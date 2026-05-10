// SyncWorker drains the SyncQueue table when connectivity is restored.
//
// Contract:
//   - Processes operations in insertion order (auto-increment id)
//   - Retries up to 3 times per operation before marking it failed
//   - Only handles "match_entries" collection for now; extend via _handlers map
//   - Called from the Riverpod provider on connectivity change
//   - Safe to call concurrently — a lock prevents overlapping runs

library;

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:matchlog/core/utils/app_logger.dart';

import '../database/app_database.dart';
import '../../features/diary/data/diary_firebase_source.dart';
import '../../features/diary/domain/entities/match_entry.dart' as domain;

class SyncWorker {
  final AppDatabase _database;
  final DiaryFirebaseSource _diaryRemote;

  // Prevents concurrent drain runs.
  bool _running = false;

  SyncWorker({
    required AppDatabase database,
    required DiaryFirebaseSource diaryRemote,
  })  : _database = database,
        _diaryRemote = diaryRemote;

  static const int _maxRetries = 3;

  /// Drain all pending (non-completed, non-failed) operations from the queue.
  /// Returns the number of operations successfully processed.
  Future<int> drain() async {
    if (_running) {
      AppLogger.log('SyncWorker already running — skipping', tag: 'Sync');
      return 0;
    }
    _running = true;
    var processed = 0;

    try {
      final pending = await _getPending();
      AppLogger.log(
        'SyncWorker: ${pending.length} pending operation(s)',
        tag: 'Sync',
      );

      for (final op in pending) {
        final success = await _process(op);
        if (success) {
          await _markCompleted(op.id);
          processed++;
        } else {
          final nextRetry = op.retryCount + 1;
          if (nextRetry >= _maxRetries) {
            await _markFailed(op.id);
            AppLogger.log(
              'SyncWorker: op ${op.id} failed after $_maxRetries retries',
              tag: 'Sync',
            );
          } else {
            await _incrementRetry(op.id, nextRetry);
          }
        }
      }
    } finally {
      _running = false;
    }

    return processed;
  }

  // Dispatch a single operation to the correct handler.
  Future<bool> _process(SyncOperation op) async {
    try {
      AppLogger.log(
        'SyncWorker: processing ${op.operation} on ${op.collection}/${op.documentId}',
        tag: 'Sync',
      );

      switch (op.collection) {
        case 'match_entries':
          return await _handleMatchEntry(op);
        default:
          // Unknown collection — skip without failing so it doesn't block the queue.
          AppLogger.log(
            'SyncWorker: unknown collection "${op.collection}" — skipping',
            tag: 'Sync',
          );
          return true;
      }
    } catch (e, st) {
      AppLogger.log(
        'SyncWorker: error processing op ${op.id}: $e',
        tag: 'Sync',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  // Handle match_entries create / delete operations.
  Future<bool> _handleMatchEntry(SyncOperation op) async {
    switch (op.operation) {
      case 'create':
        final json = jsonDecode(op.payload) as Map<String, dynamic>;
        final entry = domain.MatchEntry.fromJson(json);

        // Upload any local photos first.
        final localPhotos =
            entry.photos.where((p) => !p.startsWith('http')).toList();
        var syncedEntry = entry;

        if (localPhotos.isNotEmpty) {
          final remoteUrls = await _diaryRemote.uploadPhotos(
            userId: entry.userId,
            entryId: entry.id,
            localPaths: localPhotos,
          );
          final existingRemote =
              entry.photos.where((p) => p.startsWith('http')).toList();
          syncedEntry = entry.copyWith(
            photos: [...existingRemote, ...remoteUrls],
          );

          // Persist the remote URLs locally so the UI shows them.
          await (_database.update(_database.matchEntries)
                ..where((t) => t.id.equals(entry.id)))
              .write(
            MatchEntriesCompanion(
              photos: Value(syncedEntry.photos.cast<dynamic>()),
            ),
          );
        }

        await _diaryRemote.createEntry(syncedEntry).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException(
            'Firestore write timed out after 15s for ${entry.id}',
          ),
        );

        // Mark the local row as synced.
        await (_database.update(_database.matchEntries)
              ..where((t) => t.id.equals(entry.id)))
            .write(const MatchEntriesCompanion(synced: Value(true)));

        AppLogger.firebase(
          'SyncWorker: Firestore write success for ${entry.id}',
        );
        return true;

      case 'delete':
        // Best-effort — if the doc is already gone, that's fine.
        try {
          // We need userId to build the Firestore path.
          // It's stored in the payload for delete ops; fall back to documentId only.
          final json = jsonDecode(op.payload) as Map<String, dynamic>;
          final userId = json['userId'] as String? ?? '';
          if (userId.isNotEmpty) {
            await _diaryRemote.deleteEntry(
              userId: userId,
              entryId: op.documentId,
            );
            await _diaryRemote.deleteEntryPhotos(
              userId: userId,
              entryId: op.documentId,
            );
          }
        } on Exception {
          // Swallow — remote doc may already be gone.
        }
        return true;

      default:
        AppLogger.log(
          'SyncWorker: unknown operation "${op.operation}" — skipping',
          tag: 'Sync',
        );
        return true;
    }
  }

  // Fetch all pending operations ordered by insertion time.
  Future<List<SyncOperation>> _getPending() {
    return (_database.select(_database.syncQueue)
          ..where(
            (t) => t.completed.equals(false) & t.failed.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Future<void> _markCompleted(int id) {
    return (_database.update(_database.syncQueue)
          ..where((t) => t.id.equals(id)))
        .write(const SyncQueueCompanion(completed: Value(true)));
  }

  Future<void> _markFailed(int id) {
    return (_database.update(_database.syncQueue)
          ..where((t) => t.id.equals(id)))
        .write(const SyncQueueCompanion(failed: Value(true)));
  }

  Future<void> _incrementRetry(int id, int newCount) {
    return (_database.update(_database.syncQueue)
          ..where((t) => t.id.equals(id)))
        .write(SyncQueueCompanion(retryCount: Value(newCount)));
  }
}
