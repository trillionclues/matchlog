// Predictions DAO. Typed queries for the Predictions table. Used by PredictionRepositoryImpl
// for Phase 2-3 prediction and league features.

// Key constraint: predictions cannot be submitted after kickoffAt.
// This is enforced at the repository/usecase level, not the DAO.
library;

import 'package:drift/drift.dart';
import '../app_database.dart';

part 'prediction_dao.g.dart';

@DriftAccessor(tables: [Predictions])
class PredictionDao extends DatabaseAccessor<AppDatabase>
    with _$PredictionDaoMixin {
  PredictionDao(super.db);

  Future<void> insertPrediction(PredictionsCompanion prediction) =>
      into(predictions).insert(prediction);

  Future<void> upsertPrediction(PredictionsCompanion prediction) =>
      into(predictions).insertOnConflictUpdate(prediction);

  Future<bool> updatePrediction(PredictionsCompanion prediction) =>
      update(predictions).replace(prediction);

  // Settle a prediction after the match result is known.
  Future<void> settlePrediction({
    required String id,
    required bool correct,
    required int points,
  }) =>
      (update(predictions)..where((t) => t.id.equals(id))).write(
        PredictionsCompanion(
          settled: const Value(true),
          correct: Value(correct),
          points: Value(points),
        ),
      );

  Future<void> markSynced(String id) =>
      (update(predictions)..where((t) => t.id.equals(id)))
          .write(const PredictionsCompanion(synced: Value(true)));

  // Watch all predictions for a group — reactive stream for the prediction board.
  Stream<List<Prediction>> watchPredictionsForGroup(String groupId) =>
      (select(predictions)
            ..where((t) => t.groupId.equals(groupId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<List<Prediction>> getPredictionsForGroup(String groupId) =>
      (select(predictions)
            ..where((t) => t.groupId.equals(groupId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  // Fetch a user's predictions for a specific fixture.
  Future<List<Prediction>> getPredictionsForFixture(
    String userId,
    String fixtureId,
  ) =>
      (select(predictions)
            ..where((t) =>
                t.userId.equals(userId) & t.fixtureId.equals(fixtureId)))
          .get();

  // Fetch unsettled predictions — used by the background settlement worker.
  Future<List<Prediction>> getUnsettledPredictions(String userId) =>
      (select(predictions)
            ..where((t) =>
                t.userId.equals(userId) & t.settled.equals(false)))
          .get();

  // Fetch all unsettled predictions across all users (for batch settlement).
  Future<List<Prediction>> getAllUnsettledPredictions() =>
      (select(predictions)..where((t) => t.settled.equals(false))).get();

  Future<List<Prediction>> getUnsyncedPredictions() =>
      (select(predictions)
            ..where((t) => t.synced.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<Prediction?> getPredictionById(String id) =>
      (select(predictions)..where((t) => t.id.equals(id))).getSingleOrNull();
}
