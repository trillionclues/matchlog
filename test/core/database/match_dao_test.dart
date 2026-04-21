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

  MatchEntriesCompanion entry({
    String id = 'entry_1',
    String userId = 'user_1',
    bool synced = false,
  }) {
    return MatchEntriesCompanion.insert(
      id: id,
      userId: userId,
      sport: Sport.football,
      fixtureId: 'fixture_1',
      homeTeam: 'Arsenal',
      score: '2-1',
      league: 'Premier League',
      watchType: WatchType.tv,
      rating: 4,
      createdAt: DateTime.now(),
      synced: Value(synced),
    );
  }

  group('MatchDao', () {
    test('insertMatch then getMatchesByUser returns the entry', () async {
      await db.matchDao.insertMatch(entry());
      final results = await db.matchDao.getMatchesByUser('user_1');
      expect(results.length, 1);
      expect(results.first.homeTeam, 'Arsenal');
      expect(results.first.rating, 4);
    });

    test('getMatchesByUser returns only entries for that user', () async {
      await db.matchDao.insertMatch(entry(id: 'e1', userId: 'user_1'));
      await db.matchDao.insertMatch(entry(id: 'e2', userId: 'user_2'));
      final results = await db.matchDao.getMatchesByUser('user_1');
      expect(results.length, 1);
      expect(results.first.userId, 'user_1');
    });

    test('getUnsyncedMatches returns only unsynced entries', () async {
      await db.matchDao.insertMatch(entry(id: 'e1', synced: false));
      await db.matchDao.insertMatch(entry(id: 'e2', synced: true));
      final unsynced = await db.matchDao.getUnsyncedMatches();
      expect(unsynced.length, 1);
      expect(unsynced.first.id, 'e1');
    });

    test('markSynced updates synced flag to true', () async {
      await db.matchDao.insertMatch(entry(id: 'e1', synced: false));
      await db.matchDao.markSynced('e1');
      final unsynced = await db.matchDao.getUnsyncedMatches();
      expect(unsynced.length, 0);
    });

    test('deleteMatch removes the entry', () async {
      await db.matchDao.insertMatch(entry());
      await db.matchDao.deleteMatch('entry_1');
      final results = await db.matchDao.getMatchesByUser('user_1');
      expect(results.length, 0);
    });

    test('watchMatchesByUser emits updated list on insert', () async {
      final stream = db.matchDao.watchMatchesByUser('user_1');
      expectLater(
        stream,
        emitsInOrder([
          isEmpty,
          hasLength(1),
        ]),
      );
      await Future.delayed(const Duration(milliseconds: 10));
      await db.matchDao.insertMatch(entry());
    });
  });
}
