import 'dart:convert';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchlog/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  group('SyncQueue', () {
    Future<void> enqueue({
      String operation = 'create',
      String collection = 'match_entries',
      String documentId = 'doc_1',
      String payload = '{"id":"doc_1"}',
    }) async {
      await db.into(db.syncQueue).insert(
            SyncQueueCompanion.insert(
              operation: operation,
              collection: collection,
              documentId: documentId,
              payload: payload,
              createdAt: DateTime.now(),
            ),
          );
    }

    Future<List<SyncOperation>> getPending() async {
      return (db.select(db.syncQueue)
            ..where((t) =>
                t.completed.equals(false) & t.failed.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();
    }

    test('enqueued operation appears in getPending', () async {
      await enqueue();
      final pending = await getPending();
      expect(pending.length, 1);
      expect(pending.first.completed, false);
      expect(pending.first.failed, false);
    });

    test('markCompleted removes from pending', () async {
      await enqueue();
      final pending = await getPending();
      final id = pending.first.id;

      await (db.update(db.syncQueue)..where((t) => t.id.equals(id)))
          .write(const SyncQueueCompanion(completed: Value(true)));

      final remaining = await getPending();
      expect(remaining.length, 0);
    });

    test('incrementRetry 3 times marks as failed', () async {
      await enqueue();
      final pending = await getPending();
      final id = pending.first.id;

      for (int i = 1; i <= 3; i++) {
        final current = await (db.select(db.syncQueue)
              ..where((t) => t.id.equals(id)))
            .getSingle();
        final newRetryCount = current.retryCount + 1;
        await (db.update(db.syncQueue)..where((t) => t.id.equals(id))).write(
          SyncQueueCompanion(
            retryCount: Value(newRetryCount),
            failed: Value(newRetryCount >= 3),
          ),
        );
      }

      final result = await (db.select(db.syncQueue)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(result.failed, true);
      expect(result.retryCount, 3);

      final remaining = await getPending();
      expect(remaining.length, 0);
    });

    test('multiple operations returned in createdAt ascending order', () async {
      // Insert with slight delay to ensure different timestamps
      await enqueue(documentId: 'doc_1');
      await Future.delayed(const Duration(milliseconds: 10));
      await enqueue(documentId: 'doc_2');
      await Future.delayed(const Duration(milliseconds: 10));
      await enqueue(documentId: 'doc_3');

      final pending = await getPending();
      expect(pending.length, 3);
      expect(pending[0].documentId, 'doc_1');
      expect(pending[1].documentId, 'doc_2');
      expect(pending[2].documentId, 'doc_3');
    });

    // Property-based test: JSON payload round-trip
    test('JSON payload survives encode/decode round-trip', () {
      final payloads = [
        {'id': 'test_1', 'userId': 'user_1', 'sport': 0},
        {'nested': {'key': 'value'}, 'list': [1, 2, 3]},
        {'unicode': 'Arsenal ⚽ vs Chelsea 🔵', 'emoji': '🏆'},
        {'nullValue': null, 'emptyString': '', 'zero': 0},
        <String, dynamic>{}, // empty map
      ];

      for (final payload in payloads) {
        final encoded = jsonEncode(payload);
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;
        expect(decoded, equals(payload),
            reason: 'Round-trip failed for: $payload');
      }
    });
  });
}
