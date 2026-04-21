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

  BetEntriesCompanion bet({
    String id = 'bet_1',
    String userId = 'user_1',
    bool settled = false,
    bool synced = false,
  }) {
    return BetEntriesCompanion.insert(
      id: id,
      userId: userId,
      sport: Sport.football,
      fixtureId: 'fixture_1',
      matchDescription: 'Arsenal vs Chelsea',
      betType: BetType.win,
      prediction: 'Arsenal to Win',
      odds: 2.10,
      stake: 1000.0,
      bookmaker: 'bet9ja',
      settled: Value(settled),
      visibility: BetVisibility.private_,
      createdAt: DateTime.now(),
      synced: Value(synced),
    );
  }

  group('BetDao', () {
    test('insertBet then getBetsByUser returns the entry', () async {
      await db.betDao.insertBet(bet());
      final results = await db.betDao.getBetsByUser('user_1');
      expect(results.length, 1);
      expect(results.first.prediction, 'Arsenal to Win');
      expect(results.first.odds, 2.10);
    });

    test('getUnsettledBets returns only unsettled bets', () async {
      await db.betDao.insertBet(bet(id: 'b1', settled: false));
      await db.betDao.insertBet(bet(id: 'b2', settled: true));
      final unsettled = await db.betDao.getUnsettledBets('user_1');
      expect(unsettled.length, 1);
      expect(unsettled.first.id, 'b1');
    });

    test('getUnsyncedBets returns only unsynced bets', () async {
      await db.betDao.insertBet(bet(id: 'b1', synced: false));
      await db.betDao.insertBet(bet(id: 'b2', synced: true));
      final unsynced = await db.betDao.getUnsyncedBets();
      expect(unsynced.length, 1);
      expect(unsynced.first.id, 'b1');
    });

    test('settleBet updates settled, won, payout, settledAt', () async {
      await db.betDao.insertBet(bet());
      final settledAt = DateTime.now();
      await db.betDao.settleBet(
        id: 'bet_1',
        won: true,
        payout: 2100.0,
        settledAt: settledAt,
      );
      final result = await db.betDao.getBetById('bet_1');
      expect(result!.settled, true);
      expect(result.won, true);
      expect(result.payout, 2100.0);
    });

    test('deleteBet removes the entry', () async {
      await db.betDao.insertBet(bet());
      await db.betDao.deleteBet('bet_1');
      final results = await db.betDao.getBetsByUser('user_1');
      expect(results.length, 0);
    });
  });
}
