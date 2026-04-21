import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchlog/core/database/app_database.dart';
import 'package:matchlog/core/database/type_converters.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> insertGroup() async {
    await db.into(db.bookieGroups).insert(
          BookieGroupsCompanion.insert(
            id: 'group_1',
            name: 'Test Group',
            adminId: 'user_1',
            privacy: GroupPrivacy.inviteOnly,
            inviteCode: 'TST001',
            createdAt: DateTime.now(),
          ),
        );
  }

  PredictionsCompanion prediction({
    String id = 'pred_1',
    String userId = 'user_1',
    String groupId = 'group_1',
    bool settled = false,
  }) {
    return PredictionsCompanion.insert(
      id: id,
      userId: userId,
      groupId: Value(groupId),
      fixtureId: 'fixture_1',
      matchDescription: 'Arsenal vs Chelsea',
      prediction: 'Arsenal 2-1',
      confidence: PredictionConfidence.high,
      settled: Value(settled),
      kickoffAt: DateTime.now().add(const Duration(hours: 2)),
      createdAt: DateTime.now(),
    );
  }

  group('PredictionDao', () {
    test('insertPrediction then getPredictionsForGroup returns the entry',
        () async {
      await insertGroup();
      await db.predictionDao.insertPrediction(prediction());
      final results = await db.predictionDao.getPredictionsForGroup('group_1');
      expect(results.length, 1);
      expect(results.first.prediction, 'Arsenal 2-1');
    });

    test('watchPredictionsForGroup emits updated list on insert', () async {
      await insertGroup();
      final stream = db.predictionDao.watchPredictionsForGroup('group_1');

      expectLater(
        stream,
        emitsInOrder([
          isEmpty,
          hasLength(1),
        ]),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      await db.predictionDao.insertPrediction(prediction());
    });

    test('getUnsettledPredictions returns only unsettled', () async {
      await insertGroup();
      await db.predictionDao
          .insertPrediction(prediction(id: 'p1', settled: false));
      await db.predictionDao
          .insertPrediction(prediction(id: 'p2', settled: true));
      final unsettled =
          await db.predictionDao.getUnsettledPredictions('user_1');
      expect(unsettled.length, 1);
      expect(unsettled.first.id, 'p1');
    });

    test('settlePrediction updates correct and points', () async {
      await insertGroup();
      await db.predictionDao.insertPrediction(prediction());
      await db.predictionDao.settlePrediction(
        id: 'pred_1',
        correct: true,
        points: 3,
      );
      final result = await db.predictionDao.getPredictionById('pred_1');
      expect(result!.settled, true);
      expect(result.correct, true);
      expect(result.points, 3);
    });

    test('getUnsyncedPredictions returns only unsynced', () async {
      await insertGroup();
      await db.predictionDao.insertPrediction(prediction(id: 'p1'));
      final unsynced = await db.predictionDao.getUnsyncedPredictions();
      expect(unsynced.length, 1);
      await db.predictionDao.markSynced('p1');
      final afterSync = await db.predictionDao.getUnsyncedPredictions();
      expect(afterSync.length, 0);
    });
  });
}
