// Bet tracking DAO. Typed queries for the BetEntries table.
// Used by BettingRepositoryImpl to read and write bet entries from local SQLite.

// - getUnsettledBets: shown in the "Pending" tab of the betting screen
// - getUnsyncedBets: used by the SyncQueue worker
// - watchBetsByUser: reactive stream for the betting feed
library;

import 'package:drift/drift.dart';
import '../app_database.dart';

part 'bet_dao.g.dart';

@DriftAccessor(tables: [BetEntries])
class BetDao extends DatabaseAccessor<AppDatabase> with _$BetDaoMixin {
  BetDao(super.db);

  Future<void> insertBet(BetEntriesCompanion entry) =>
      into(betEntries).insert(entry);

  Future<void> upsertBet(BetEntriesCompanion entry) =>
      into(betEntries).insertOnConflictUpdate(entry);

  Future<bool> updateBet(BetEntriesCompanion entry) =>
      update(betEntries).replace(entry);

  Future<int> deleteBet(String id) =>
      (delete(betEntries)..where((t) => t.id.equals(id))).go();

  // Settle a bet — sets won, payout, settledAt, and settled=true.
  Future<void> settleBet({
    required String id,
    required bool won,
    required double payout,
    required DateTime settledAt,
  }) =>
      (update(betEntries)..where((t) => t.id.equals(id))).write(
        BetEntriesCompanion(
          settled: const Value(true),
          won: Value(won),
          payout: Value(payout),
          settledAt: Value(settledAt),
        ),
      );

  Future<void> markSynced(String id) =>
      (update(betEntries)..where((t) => t.id.equals(id)))
          .write(const BetEntriesCompanion(synced: Value(true)));

  // Watch all bet entries for a user, most recent first.
  Stream<List<BetEntry>> watchBetsByUser(String userId) =>
      (select(betEntries)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<List<BetEntry>> getBetsByUser(String userId) =>
      (select(betEntries)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  // Fetch pending (unsettled) bets — shown in the "Pending" tab.
  Future<List<BetEntry>> getUnsettledBets(String userId) =>
      (select(betEntries)
            ..where((t) =>
                t.userId.equals(userId) & t.settled.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  // Fetch settled bets — shown in the "History" tab.
  Future<List<BetEntry>> getSettledBets(String userId) =>
      (select(betEntries)
            ..where((t) =>
                t.userId.equals(userId) & t.settled.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.settledAt)]))
          .get();

  Future<BetEntry?> getBetById(String id) =>
      (select(betEntries)..where((t) => t.id.equals(id))).getSingleOrNull();

  // Fetch all unsynced bets for the SyncQueue worker.
  Future<List<BetEntry>> getUnsyncedBets() =>
      (select(betEntries)
            ..where((t) => t.synced.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  ///Fetch all settled bets for ROI calculation.
  // Used by CalculateRoi usecase.
  Future<List<BetEntry>> getSettledBetsForStats(String userId) =>
      (select(betEntries)
            ..where((t) =>
                t.userId.equals(userId) & t.settled.equals(true)))
          .get();
}
