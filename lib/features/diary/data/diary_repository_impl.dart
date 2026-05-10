// This composes DiaryLocalSource and DiaryFirebaseSource with offline-first contract:
//   - Writes land locally first (success boundary for the user)
//   - Remote sync is best-effort; failures are queued for retry
//   - Reads always come from the local Drift stream
//   - Background refresh merges remote snapshots into local cache

library;

import 'dart:async';
import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:matchlog/core/utils/app_logger.dart';
import '../../../core/database/app_database.dart';
import '../domain/entities/match_entry.dart' as domain;
import '../domain/entities/user_stats.dart';
import '../domain/utils/streak_calculator.dart';
import '../domain/failures/diary_failure.dart';
import '../domain/repositories/diary_repository.dart';
import 'diary_firebase_source.dart';
import 'diary_local_source.dart';

class DiaryRepositoryImpl implements DiaryRepository {
  final DiaryLocalSource _local;
  final DiaryFirebaseSource _remote;
  final AppDatabase _database;
  final bool Function() _isOnline;

  DiaryRepositoryImpl({
    required DiaryLocalSource local,
    required DiaryFirebaseSource remote,
    required AppDatabase database,
    required bool Function() isOnline,
  })  : _local = local,
        _remote = remote,
        _database = database,
        _isOnline = isOnline;

  // 1. Insert locally (this is the success boundary)
  // 2. If online: upload photos → write Firestore → mark synced
  // 3. If offline or remote fails: enqueue sync operation

  @override
  Future<Either<DiaryFailure, Unit>> logMatch(domain.MatchEntry entry) async {
    try {
      if (entry.rating < 1 || entry.rating > 5) {
        return const Left(
          DiaryFailure.validation('Rating must be between 1 and 5.'),
        );
      }

      AppLogger.db('Inserting entry locally: ${entry.id}');
      await _local.insertEntry(entry);
      AppLogger.db('Local insert success: ${entry.id}');

      if (_isOnline()) {
        AppLogger.firebase('Online — firing background sync for: ${entry.id}');
        unawaited(_syncEntryToRemote(entry));
      } else {
        AppLogger.diary('Offline — queuing create for: ${entry.id}');
        await _enqueueSync(operation: 'create', entry: entry);
      }

      return const Right(unit);
    } catch (e, st) {
      AppLogger.diary('logMatch failed', error: e, st: st);
      return Left(DiaryFailure.storage(e.toString()));
    }
  }

  // Local Drift stream emits immediately.
  // Fire-and-forget background refresh when online without blanking the local list.

  @override
  Future<List<domain.MatchEntry>> getEntries({
    required String userId,
    DiaryFilter filter = DiaryFilter.all,
  }) async {
    final local = await _local.getEntries(userId: userId, filter: filter);

    if (_isOnline()) {
      _backgroundRefresh(userId);
    }

    return local;
  }

  @override
  Stream<List<domain.MatchEntry>> watchEntries({
    required String userId,
    DiaryFilter filter = DiaryFilter.all,
  }) {
    // Trigger background refresh once when stream is first listened to.
    if (_isOnline()) {
      _backgroundRefresh(userId);
    }

    return _local.watchEntries(userId: userId, filter: filter);
  }

  @override
  Future<domain.MatchEntry?> getEntryById({
    required String userId,
    required String entryId,
  }) {
    return _local.getEntryById(entryId);
  }

  // 1. Delete local row immediately
  // 2. If online: delete Firestore doc + Storage photos
  // 3. If offline: enqueue delete operation

  @override
  Future<Either<DiaryFailure, Unit>> deleteEntry({
    required String userId,
    required String entryId,
  }) async {
    try {
      await _local.deleteEntry(entryId);

      if (_isOnline()) {
        try {
          await _remote.deleteEntry(userId: userId, entryId: entryId);
          await _remote.deleteEntryPhotos(userId: userId, entryId: entryId);
        } catch (_) {
          await _enqueueSync(
            operation: 'delete',
            documentId: entryId,
            userId: userId,
            collection: 'match_entries',
          );
        }
      } else {
        await _enqueueSync(
          operation: 'delete',
          documentId: entryId,
          userId: userId,
          collection: 'match_entries',
        );
      }

      return const Right(unit);
    } catch (e) {
      return Left(DiaryFailure.storage(e.toString()));
    }
  }

  @override
  Future<UserStats> calculateStats({required String userId}) async {
    final entries = await _local.getEntries(userId: userId);

    if (entries.isEmpty) return const UserStats();

    final now = DateTime.now();
    final thisMonth = entries.where(
      (e) => e.createdAt.year == now.year && e.createdAt.month == now.month,
    );

    final leagueCounts = <String, int>{};
    final teamCounts = <String, int>{};
    final watchTypeCounts = <String, int>{};
    var ratingSum = 0;
    var stadiumVisits = 0;

    for (final entry in entries) {
      leagueCounts[entry.league] = (leagueCounts[entry.league] ?? 0) + 1;

      teamCounts[entry.homeTeam] = (teamCounts[entry.homeTeam] ?? 0) + 1;
      if (entry.awayTeam != null) {
        teamCounts[entry.awayTeam!] = (teamCounts[entry.awayTeam!] ?? 0) + 1;
      }

      watchTypeCounts[entry.watchType] =
          (watchTypeCounts[entry.watchType] ?? 0) + 1;

      ratingSum += entry.rating;

      if (entry.watchType == 'stadium') stadiumVisits++;
    }

    // Calculate streaks for consecutive days with at least one entry.
    final streaks = _calculateStreaks(entries);

    return UserStats(
      totalMatchesWatched: entries.length,
      matchesThisMonth: thisMonth.length,
      matchesByLeague: leagueCounts,
      matchesByTeam: teamCounts,
      matchesByWatchType: watchTypeCounts,
      averageRating: ratingSum / entries.length,
      stadiumVisits: stadiumVisits,
      currentStreak: streaks.$1,
      longestStreak: streaks.$2,
    );
  }

  // Attempt to sync a single entry to Firebase (photos + document).
  Future<void> _syncEntryToRemote(domain.MatchEntry entry) async {
    try {
      AppLogger.firebase('Starting remote sync: ${entry.id}');
      var syncedEntry = entry;

      final localPhotos =
          entry.photos.where((p) => !p.startsWith('http')).toList();

      if (localPhotos.isNotEmpty) {
        final remoteUrls = await _remote.uploadPhotos(
          userId: entry.userId,
          entryId: entry.id,
          localPaths: localPhotos,
        );

        // Merge: keep existing remote URLs + newly uploaded ones.
        final existingRemote =
            entry.photos.where((p) => p.startsWith('http')).toList();
        final allUrls = [...existingRemote, ...remoteUrls];

        syncedEntry = entry.copyWith(photos: allUrls);
        await _local.updatePhotoUrls(entry.id, allUrls);
      }

      await _remote.createEntry(syncedEntry).timeout(const Duration(seconds: 20));
      AppLogger.firebase('Firestore write success: ${entry.id}');

      await _local.markSynced(entry.id);
    } on TimeoutException {
    AppLogger.firebase('Remote sync timed out — queuing: ${entry.id}');
    await _enqueueSync(operation: 'create', entry: entry);
  } catch (_) {
      await _enqueueSync(operation: 'create', entry: entry);
    }
  }

  // Merge remote entries into local Drift cache.
  Future<void> _backgroundRefresh(String userId) async {
    try {
      final remoteEntries = await _remote.fetchEntries(userId);
      for (final remote in remoteEntries) {
        await _local.upsertEntry(remote);
        await _local.markSynced(remote.id);
      }
    } catch (_) {
      // don't disrupt the local stream.
    }
  }

  Future<void> _enqueueSync({
    required String operation,
    domain.MatchEntry? entry,
    String? documentId,
    String? userId,
    String? collection,
  }) async {
    // For delete ops, embed userId in the payload so the worker can build
    // the Firestore path without needing to look up the local row.
    final payload = entry != null
        ? jsonEncode(entry.toJson())
        : (userId != null ? jsonEncode({'userId': userId}) : '{}');

    await _database.into(_database.syncQueue).insert(
          SyncQueueCompanion.insert(
            operation: operation,
            collection: collection ?? 'match_entries',
            documentId: documentId ?? entry?.id ?? '',
            payload: payload,
            createdAt: DateTime.now(),
          ),
        );
  }

  // Calculate current and longest streaks from entries sorted by createdAt.
  (int current, int longest) _calculateStreaks(
      List<domain.MatchEntry> entries) {
    return calculateStreaks(entries);
  }
}
