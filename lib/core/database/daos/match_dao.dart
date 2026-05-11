// Match diary DAO. Typed queries for the MatchEntries table. Used by DiaryRepositoryImpl
// to read and write match diary entries from local SQLite.

// All write methods return the inserted/updated row count.
// Watch methods return a Stream for reactive UI updates.
// Unsynced queries are used by the SyncQueue worker.
library;

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../type_converters.dart';

part 'match_dao.g.dart';

@DriftAccessor(tables: [MatchEntries])
class MatchDao extends DatabaseAccessor<AppDatabase> with _$MatchDaoMixin {
  MatchDao(super.db);

// Insert a new match entry. Throws if [id] already exists.
  Future<void> insertMatch(MatchEntriesCompanion entry) =>
      into(matchEntries).insert(entry);

  // Insert or replace an existing match entry (used during remote sync).
  Future<void> upsertMatch(MatchEntriesCompanion entry) =>
      into(matchEntries).insertOnConflictUpdate(entry);

  // Update an existing match entry by ID.
  Future<bool> updateMatch(MatchEntriesCompanion entry) =>
      update(matchEntries).replace(entry);

  // Delete a match entry by ID.
  Future<int> deleteMatch(String id) =>
      (delete(matchEntries)..where((t) => t.id.equals(id))).go();

  // Mark a match entry as synced after successful Firebase write.
  Future<void> markSynced(String id) =>
      (update(matchEntries)..where((t) => t.id.equals(id)))
          .write(const MatchEntriesCompanion(synced: Value(true)));

  // Update only geoVerified field for a match entry.
  Future<void> updateGeoVerified(String id, bool geoVerified) =>
      (update(matchEntries)..where((t) => t.id.equals(id)))
          .write(MatchEntriesCompanion(geoVerified: Value(geoVerified)));
          
  // Watch all match entries for a user, ordered by most recent first.
  // Returns a reactive stream — UI rebuilds automatically on changes.
  Stream<List<MatchEntry>> watchMatchesByUser(String userId) =>
      (select(matchEntries)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  // One-shot fetch of all match entries for a user.
  Future<List<MatchEntry>> getMatchesByUser(String userId) =>
      (select(matchEntries)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  // Fetch match entries filtered by sport.
  Future<List<MatchEntry>> getMatchesBySport(String userId, Sport sport) =>
      (select(matchEntries)
            ..where((t) =>
                t.userId.equals(userId) & t.sport.equals(sport.index))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  // Fetch a single match entry by ID. Returns null if not found.
  Future<MatchEntry?> getMatchById(String id) =>
      (select(matchEntries)..where((t) => t.id.equals(id))).getSingleOrNull();

  // Fetch all entries not yet synced to Firebase.
  // Used by the SyncQueue worker to replay pending operations.
  Future<List<MatchEntry>> getUnsyncedMatches() =>
      (select(matchEntries)
            ..where((t) => t.synced.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  // Count total match entries for a user (used in stats dashboard).
  Future<int> countMatchesByUser(String userId) async {
    final count = matchEntries.id.count();
    final query = selectOnly(matchEntries)
      ..addColumns([count])
      ..where(matchEntries.userId.equals(userId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
