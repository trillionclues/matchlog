// DiaryLocalSource wraps the existing MatchDao and provides domain-level
// mapping between Drift's MatchEntry (data class) and the feature's
// domain MatchEntry (Freezed entity).
//
// This source is the primary read path — all screens read local-first.
// Sync state updates (markSynced, updatePhotos) are called by the repository
// after successful remote operations.
library;

import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/daos/match_dao.dart';
import '../../../core/database/type_converters.dart';
import '../domain/entities/match_entry.dart' as domain;
import '../domain/repositories/diary_repository.dart';

class DiaryLocalSource {
  final MatchDao _dao;

  const DiaryLocalSource(this._dao);

  // Insert new match entry from the domain entity.
  Future<void> insertEntry(domain.MatchEntry entry) {
    return _dao.insertMatch(_toCompanion(entry));
  }

  // Insert or replace existing entry (used during remote sync merge).
  Future<void> upsertEntry(domain.MatchEntry entry) {
    return _dao.upsertMatch(_toCompanion(entry));
  }

  // Delete match entry by ID.
  Future<int> deleteEntry(String id) {
    return _dao.deleteMatch(id);
  }

  // Mark entry as synced after successful Firebase write.
  Future<void> markSynced(String id) {
    return _dao.markSynced(id);
  }

  // Rewrite local photo paths to remote Storage URLs after upload.
  Future<void> updatePhotoUrls(String id, List<String> remoteUrls) {
    return (_dao.update(_dao.matchEntries)..where((t) => t.id.equals(id)))
        .write(
      db.MatchEntriesCompanion(
        photos: Value(remoteUrls.cast<dynamic>()),
      ),
    );
  }

  // Watch all entries for a user, optionally filtered by watch type.
  // Returns domain entities sorted by createdAt DESC.
  Stream<List<domain.MatchEntry>> watchEntries({
    required String userId,
    DiaryFilter filter = DiaryFilter.all,
  }) {
    return _dao.watchMatchesByUser(userId).map(
          (rows) => _filterAndMap(rows, filter),
        );
  }

  // One-shot fetch of all entries for a user with optional filter.
  Future<List<domain.MatchEntry>> getEntries({
    required String userId,
    DiaryFilter filter = DiaryFilter.all,
  }) async {
    final rows = await _dao.getMatchesByUser(userId);
    return _filterAndMap(rows, filter);
  }

  // Fetch a single entry by ID. Returns null if not found.
  Future<domain.MatchEntry?> getEntryById(String id) async {
    final row = await _dao.getMatchById(id);
    return row != null ? _toDomain(row) : null;
  }

  // Fetch all entries not yet synced to Firebase.
  Future<List<domain.MatchEntry>> getUnsyncedEntries() async {
    final rows = await _dao.getUnsyncedMatches();
    return rows.map(_toDomain).toList();
  }

  // Count total entries for a user (used in stats).
  Future<int> countEntries(String userId) {
    return _dao.countMatchesByUser(userId);
  }

  // Filter rows by watch type and convert to domain entities.
  List<domain.MatchEntry> _filterAndMap(
    List<db.MatchEntry> rows,
    DiaryFilter filter,
  ) {
    final filtered = filter == DiaryFilter.all
        ? rows
        : rows.where((r) => _matchesFilter(r, filter));
    return filtered.map(_toDomain).toList();
  }

  // Check if Drift row matches requested filter.
  bool _matchesFilter(db.MatchEntry row, DiaryFilter filter) {
    return switch (filter) {
      DiaryFilter.all => true,
      DiaryFilter.stadium => row.watchType == WatchType.stadium,
      DiaryFilter.tv => row.watchType == WatchType.tv,
      DiaryFilter.streaming => row.watchType == WatchType.streaming,
      DiaryFilter.radio => row.watchType == WatchType.radio,
    };
  }

  // Convert Drift MatchEntry row to domain MatchEntry.
  domain.MatchEntry _toDomain(db.MatchEntry row) {
    return domain.MatchEntry(
      id: row.id,
      userId: row.userId,
      sport: row.sport.name,
      fixtureId: row.fixtureId,
      homeTeam: row.homeTeam,
      awayTeam: row.awayTeam,
      score: row.score,
      league: row.league,
      watchType: row.watchType.name,
      rating: row.rating,
      review: row.review,
      photos: row.photos.cast<String>(),
      venue: row.venue,
      sportMetadata: row.sportMetadata,
      geoVerified: row.geoVerified,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  // Convert domain MatchEntry to Drift companion for inserts/upserts.
  db.MatchEntriesCompanion _toCompanion(domain.MatchEntry entry) {
    return db.MatchEntriesCompanion(
      id: Value(entry.id),
      userId: Value(entry.userId),
      sport: Value(_parseSport(entry.sport)),
      fixtureId: Value(entry.fixtureId),
      homeTeam: Value(entry.homeTeam),
      awayTeam: Value(entry.awayTeam),
      score: Value(entry.score),
      league: Value(entry.league),
      watchType: Value(_parseWatchType(entry.watchType)),
      rating: Value(entry.rating),
      review: Value(entry.review),
      photos: Value(entry.photos.cast<dynamic>()),
      venue: Value(entry.venue),
      sportMetadata: Value(entry.sportMetadata),
      geoVerified: Value(entry.geoVerified),
      createdAt: Value(entry.createdAt),
      updatedAt: Value(entry.updatedAt),
      synced: const Value(false),
    );
  }

  // Parse sport name string back to the enum.
  Sport _parseSport(String name) {
    return Sport.values.firstWhere(
      (s) => s.name == name,
      orElse: () => Sport.football,
    );
  }

  // Parse watch type name string back to the enum.
  WatchType _parseWatchType(String name) {
    return WatchType.values.firstWhere(
      (w) => w.name == name,
      orElse: () => WatchType.tv,
    );
  }
}
