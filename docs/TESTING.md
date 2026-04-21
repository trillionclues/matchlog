# MatchLog — Testing Strategy

> Unit tests, widget tests, integration tests, and manual test plans across all phases.

---

## Testing Pyramid

```
         ▲
        / \
       / E2E \           ← Few: Critical user flows (login, log match, join group)
      /───────\
     / Widget   \        ← Medium: Screen-level tests (renders, interactions)
    /─────────────\
   /    Unit        \    ← Many: Business logic, repositories, usecases
  /───────────────────\
```

| Layer | Quantity | Speed | What to Test |
|-------|----------|-------|-------------|
| **Unit** | 60-70% | ⚡ Fast | Usecases, entities, repositories, formatters, validators |
| **Widget** | 20-30% | 🔄 Medium | Screen rendering, form behavior, UI state transitions |
| **Integration/E2E** | 5-10% | 🐢 Slow | Complete user flows end-to-end |

---

## Test Directory Structure

```
test/
├── core/
│   ├── network/
│   │   ├── api_client_test.dart
│   │   ├── connectivity_service_test.dart
│   │   └── sync_queue_test.dart
│   ├── database/
│   │   ├── match_dao_test.dart
│   │   ├── bet_dao_test.dart
│   │   └── group_dao_test.dart
│   └── utils/
│       ├── formatters_test.dart
│       └── validators_test.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository_impl_test.dart
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       ├── sign_in_test.dart
│   │   │       └── sign_up_test.dart
│   │   └── presentation/
│   │       ├── login_screen_test.dart
│   │       └── providers/
│   │           └── auth_providers_test.dart
│   │
│   ├── diary/
│   │   ├── data/
│   │   │   └── diary_repository_impl_test.dart
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       ├── log_match_test.dart
│   │   │       ├── calculate_stats_test.dart
│   │   │       └── get_diary_entries_test.dart
│   │   └── presentation/
│   │       ├── diary_screen_test.dart
│   │       ├── log_match_screen_test.dart
│   │       ├── stats_dashboard_test.dart
│   │       └── widgets/
│   │           ├── match_card_test.dart
│   │           ├── roi_chart_test.dart
│   │           └── calendar_heatmap_test.dart
│   │
│   ├── betting/
│   │   ├── data/
│   │   │   └── betting_repository_impl_test.dart
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       ├── log_bet_test.dart
│   │   │       ├── settle_bet_test.dart
│   │   │       └── calculate_roi_test.dart
│   │   └── presentation/
│   │       └── betting_screen_test.dart
│   │
│   ├── groups/
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       ├── create_group_test.dart
│   │   │       ├── join_group_test.dart
│   │   │       └── get_leaderboard_test.dart
│   │   └── presentation/
│   │       ├── group_detail_screen_test.dart
│   │       └── leaderboard_screen_test.dart
│   │
│   └── match_search/
│       ├── data/
│       │   └── football_api_source_test.dart
│       └── presentation/
│           └── search_screen_test.dart
│
├── features/
│   └── verification/
│       ├── data/
│       │   ├── ocr_service_test.dart
│       │   ├── bet9ja_parser_test.dart
│       │   ├── sportybet_parser_test.dart
│       │   ├── generic_parser_test.dart
│       │   └── verification_repository_impl_test.dart
│       ├── domain/
│       │   └── usecases/
│       │       ├── scan_bet_slip_test.dart
│       │       ├── verify_bet_slip_test.dart
│       │       ├── calculate_truth_score_test.dart
│       │       └── flag_suspicious_slip_test.dart
│       └── presentation/
│           ├── scan_slip_screen_test.dart
│           └── truth_score_screen_test.dart
│
├── fixtures/                          # JSON fixture files for API mocking
│   ├── thesportsdb/
│   │   ├── upcoming_events.json
│   │   ├── event_details.json
│   │   └── team_search.json
│   ├── api_football/
│   │   ├── fixtures_response.json
│   │   └── standings_response.json
│   └── gemini/
│       └── insight_response.json
│
├── fixtures/
│   └── ocr/                               # Sample OCR outputs for parser testing
│       ├── bet9ja_single_bet.txt
│       ├── bet9ja_accumulator.txt
│       ├── sportybet_slip.txt
│       ├── betking_slip.txt
│       ├── noisy_ocr_output.txt            # Low-confidence OCR for fallback testing
│       └── manipulated_slip.txt             # Known fake for fraud detection testing
│
├── mocks/                             # Shared mocks
│   ├── mock_repositories.dart
│   ├── mock_data_sources.dart
│   └── mock_services.dart
│
├── helpers/                           # Test utilities
│   ├── pump_app.dart                  # Wraps widget in MaterialApp + providers
│   ├── fake_data.dart                 # Factory methods for test entities
│   └── drift_test_utils.dart          # In-memory Drift database for testing
│
└── integration_test/
    ├── app_test.dart                  # Full app integration test
    ├── diary_flow_test.dart           # Log match → view diary → check stats
    ├── betting_flow_test.dart         # Log bet → settle → check ROI
    ├── group_flow_test.dart           # Create group → invite → predict → leaderboard
    └── scan_flow_test.dart            # Scan slip → review → verify → truth score
```

---

## Unit Testing

### Usecase Tests

```dart
// test/features/diary/domain/usecases/calculate_stats_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDiaryRepository extends Mock implements DiaryRepository {}
class MockBettingRepository extends Mock implements BettingRepository {}

void main() {
  late CalculateStats usecase;
  late MockDiaryRepository mockDiaryRepo;
  late MockBettingRepository mockBettingRepo;

  setUp(() {
    mockDiaryRepo = MockDiaryRepository();
    mockBettingRepo = MockBettingRepository();
    usecase = CalculateStats(mockDiaryRepo, mockBettingRepo);
  });

  group('CalculateStats', () {
    test('calculates correct win rate from settled bets', () async {
      // Arrange
      when(() => mockBettingRepo.getEntries(userId: 'user_1'))
          .thenAnswer((_) async => [
            FakeData.bet(won: true, stake: 100, payout: 200),
            FakeData.bet(won: true, stake: 100, payout: 300),
            FakeData.bet(won: false, stake: 100, payout: 0),
            FakeData.bet(won: false, stake: 100, payout: 0),
          ]);
      when(() => mockDiaryRepo.getEntries(userId: 'user_1'))
          .thenAnswer((_) async => []);

      // Act
      final stats = await usecase(userId: 'user_1');

      // Assert
      expect(stats.totalBets, 4);
      expect(stats.betsWon, 2);
      expect(stats.winRate, 50.0);
      expect(stats.totalStaked, 400.0);
      expect(stats.totalPayout, 500.0);
      expect(stats.roi, 25.0); // (500 - 400) / 400 * 100
    });

    test('handles zero bets without division by zero', () async {
      when(() => mockBettingRepo.getEntries(userId: 'user_1'))
          .thenAnswer((_) async => []);
      when(() => mockDiaryRepo.getEntries(userId: 'user_1'))
          .thenAnswer((_) async => []);

      final stats = await usecase(userId: 'user_1');

      expect(stats.totalBets, 0);
      expect(stats.winRate, 0.0);
      expect(stats.roi, 0.0);
    });

    test('calculates ROI by league correctly', () async {
      when(() => mockBettingRepo.getEntries(userId: 'user_1'))
          .thenAnswer((_) async => [
            FakeData.bet(league: 'Premier League', won: true, stake: 100, payout: 250),
            FakeData.bet(league: 'Premier League', won: false, stake: 100, payout: 0),
            FakeData.bet(league: 'La Liga', won: true, stake: 50, payout: 200),
          ]);
      when(() => mockDiaryRepo.getEntries(userId: 'user_1'))
          .thenAnswer((_) async => []);

      final stats = await usecase(userId: 'user_1');

      // PL: (250 - 200) / 200 * 100 = 25%
      expect(stats.roiByLeague['Premier League'], 25.0);
      // La Liga: (200 - 50) / 50 * 100 = 300%
      expect(stats.roiByLeague['La Liga'], 300.0);
    });
  });
}
```

### Repository Tests (Offline-First)

```dart
// test/features/diary/data/diary_repository_impl_test.dart
void main() {
  late DiaryRepositoryImpl repo;
  late MockDiaryLocalSource mockLocal;
  late MockDiaryRemoteSource mockRemote;
  late MockConnectivityService mockConnectivity;
  late MockSyncQueue mockSyncQueue;

  setUp(() {
    mockLocal = MockDiaryLocalSource();
    mockRemote = MockDiaryRemoteSource();
    mockConnectivity = MockConnectivityService();
    mockSyncQueue = MockSyncQueue();
    repo = DiaryRepositoryImpl(mockLocal, mockRemote, mockConnectivity, mockSyncQueue);
  });

  group('logMatch', () {
    test('writes to local AND remote when online', () async {
      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockLocal.insert(any())).thenAnswer((_) async {});
      when(() => mockRemote.create(any())).thenAnswer((_) async {});

      await repo.logMatch(FakeData.matchEntry());

      verify(() => mockLocal.insert(any())).called(1);
      verify(() => mockRemote.create(any())).called(1);
      verifyNever(() => mockSyncQueue.enqueue(any()));
    });

    test('writes to local and queues sync when offline', () async {
      when(() => mockConnectivity.isOnline).thenAnswer((_) async => false);
      when(() => mockLocal.insert(any())).thenAnswer((_) async {});
      when(() => mockSyncQueue.enqueue(any())).thenAnswer((_) async {});

      await repo.logMatch(FakeData.matchEntry());

      verify(() => mockLocal.insert(any())).called(1);
      verify(() => mockSyncQueue.enqueue(any())).called(1);
      verifyNever(() => mockRemote.create(any()));
    });
  });

  group('getEntries', () {
    test('returns local data immediately, then refreshes from remote', () async {
      final localEntries = [FakeData.matchEntry(), FakeData.matchEntry()];
      when(() => mockLocal.getEntries(userId: 'user_1'))
          .thenAnswer((_) async => localEntries);
      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRemote.getAll(userId: 'user_1'))
          .thenAnswer((_) async => localEntries);

      final result = await repo.getEntries(userId: 'user_1');

      expect(result, localEntries);
      verify(() => mockLocal.getEntries(userId: 'user_1')).called(1);
    });
  });
}
```

### Entity/Formatter Tests

```dart
// test/core/utils/formatters_test.dart
void main() {
  group('OddsFormatter', () {
    test('formats decimal odds with 2 decimal places', () {
      expect(OddsFormatter.format(2.5), '2.50');
      expect(OddsFormatter.format(1.05), '1.05');
      expect(OddsFormatter.format(10.0), '10.00');
    });
  });

  group('CurrencyFormatter', () {
    test('formats NGN correctly', () {
      expect(CurrencyFormatter.format(1500, 'NGN'), '₦1,500.00');
      expect(CurrencyFormatter.format(0, 'NGN'), '₦0.00');
    });

    test('formats USD correctly', () {
      expect(CurrencyFormatter.format(99.99, 'USD'), '\$99.99');
    });
  });

  group('BetEntry extensions', () {
    test('potential payout is stake * odds', () {
      final bet = FakeData.bet(stake: 100, odds: 2.5);
      expect(bet.potentialPayout, 250.0);
    });

    test('profit/loss is correct for won bet', () {
      final bet = FakeData.bet(
        stake: 100, odds: 2.5, settled: true, won: true, payout: 250,
      );
      expect(bet.profitLoss, 150.0);
    });

    test('profit/loss is negative for lost bet', () {
      final bet = FakeData.bet(
        stake: 100, settled: true, won: false, payout: 0,
      );
      expect(bet.profitLoss, -100.0);
    });
  });
}
```

---

## Widget Testing

### Screen Tests

```dart
// test/features/diary/presentation/diary_screen_test.dart
void main() {
  group('DiaryScreen', () {
    testWidgets('shows loading shimmer while fetching entries', (tester) async {
      await tester.pumpApp(
        overrides: [
          diaryEntriesProvider.overrideWith(
            (_) => const AsyncValue.loading(),
          ),
        ],
        child: const DiaryScreen(),
      );

      expect(find.byType(LoadingShimmer), findsWidgets);
    });

    testWidgets('shows empty state when no entries exist', (tester) async {
      await tester.pumpApp(
        overrides: [
          diaryEntriesProvider.overrideWith(
            (_) => const AsyncValue.data([]),
          ),
        ],
        child: const DiaryScreen(),
      );

      expect(find.text('No matches logged yet'), findsOneWidget);
      expect(find.text('Log your first match'), findsOneWidget);
    });

    testWidgets('renders match cards for each entry', (tester) async {
      final entries = [
        FakeData.matchEntry(homeTeam: 'Arsenal', awayTeam: 'Chelsea'),
        FakeData.matchEntry(homeTeam: 'Liverpool', awayTeam: 'Man City'),
      ];

      await tester.pumpApp(
        overrides: [
          diaryEntriesProvider.overrideWith(
            (_) => AsyncValue.data(entries),
          ),
        ],
        child: const DiaryScreen(),
      );

      expect(find.text('Arsenal'), findsOneWidget);
      expect(find.text('Chelsea'), findsOneWidget);
      expect(find.text('Liverpool'), findsOneWidget);
      expect(find.byType(MatchCard), findsNWidgets(2));
    });

    testWidgets('navigates to log match screen on FAB tap', (tester) async {
      await tester.pumpApp(
        overrides: [
          diaryEntriesProvider.overrideWith((_) => const AsyncValue.data([])),
        ],
        child: const DiaryScreen(),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(LogMatchScreen), findsOneWidget);
    });
  });
}
```

### Test Helper

```dart
// test/helpers/pump_app.dart
extension PumpApp on WidgetTester {
  Future<void> pumpApp({
    required Widget child,
    List<Override> overrides = const [],
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: child,
        ),
      ),
    );
  }
}
```

---

## Drift Database Tests

```dart
// test/helpers/drift_test_utils.dart
import 'package:drift/native.dart';

AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

// test/core/database/match_dao_test.dart
void main() {
  late AppDatabase db;
  late MatchDao dao;

  setUp(() {
    db = createTestDatabase();
    dao = MatchDao(db);
  });

  tearDown(() => db.close());

  test('inserts and retrieves match entry', () async {
    final entry = MatchEntriesCompanion.insert(
      id: 'test_1',
      userId: 'user_1',
      sport: Sport.football,
      fixtureId: 'fix_1',
      homeTeam: 'Arsenal',
      score: '2-1',
      league: 'Premier League',
      watchType: WatchType.tv,
      rating: 4,
      createdAt: DateTime.now(),
    );

    await dao.insertEntry(entry);
    final results = await dao.getEntriesByUser('user_1');

    expect(results.length, 1);
    expect(results.first.homeTeam, 'Arsenal');
    expect(results.first.rating, 4);
  });

  test('filters entries by sport', () async {
    await dao.insertEntry(FakeData.driftMatchEntry(sport: Sport.football));
    await dao.insertEntry(FakeData.driftMatchEntry(sport: Sport.basketball));
    await dao.insertEntry(FakeData.driftMatchEntry(sport: Sport.football));

    final footballOnly = await dao.getEntriesByUser('user_1', sport: Sport.football);
    expect(footballOnly.length, 2);
  });

  test('sync queue operations work correctly', () async {
    final syncDao = SyncQueueDao(db);

    await syncDao.enqueue(SyncOperation(
      operation: 'create',
      collection: 'match_entries',
      documentId: 'test_1',
      payload: '{}',
    ));

    final pending = await syncDao.getPending();
    expect(pending.length, 1);

    await syncDao.markCompleted(pending.first.id);
    final remaining = await syncDao.getPending();
    expect(remaining.length, 0);
  });
}
```

---

## API Mock Tests

```dart
// test/features/match_search/data/football_api_source_test.dart
void main() {
  late TheSportsDbSource source;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    source = TheSportsDbSource(mockDio, '1'); // Free API key
  });

  test('parses upcoming fixtures correctly', () async {
    // Load fixture file
    final fixtureJson = File('test/fixtures/thesportsdb/upcoming_events.json')
        .readAsStringSync();

    when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => Response(
          data: jsonDecode(fixtureJson),
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

    final fixtures = await source.getUpcoming(teamId: '133604');

    expect(fixtures.length, greaterThan(0));
    expect(fixtures.first.homeTeam, isNotEmpty);
    expect(fixtures.first.sport, Sport.football);
  });

  test('returns empty list when no events found', () async {
    when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => Response(
          data: {'events': null},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

    final fixtures = await source.getUpcoming(teamId: '999999');
    expect(fixtures, isEmpty);
  });

  test('throws on network error', () async {
    when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
        ));

    expect(
      () => source.getUpcoming(teamId: '133604'),
      throwsA(isA<DioException>()),
    );
  });
}
```

---

## Verification Tests (OCR + Truth Score)

### Truth Score Usecase Tests

```dart
// test/features/verification/domain/usecases/calculate_truth_score_test.dart
void main() {
  late CalculateTruthScore usecase;

  setUp(() {
    usecase = CalculateTruthScore();
  });

  group('CalculateTruthScore', () {
    test('returns diamond tier for highly consistent, high-volume user', () {
      final result = usecase.calculate(TruthScoreInput(
        totalScannedSlips: 200,
        verifiedSlips: 180,
        consistentSlips: 175,
        rejectedSlips: 5,
        flaggedSlips: 0,
        lastScanDate: DateTime.now().subtract(const Duration(days: 1)),
      ));

      expect(result.tier, TruthTier.diamond);
      expect(result.truthScore, greaterThanOrEqualTo(90));
    });

    test('returns unverified for user with no scans', () {
      final result = usecase.calculate(TruthScoreInput(
        totalScannedSlips: 0,
        verifiedSlips: 0,
        consistentSlips: 0,
        rejectedSlips: 0,
        flaggedSlips: 0,
        lastScanDate: DateTime.now(),
      ));

      expect(result.tier, TruthTier.unverified);
      expect(result.truthScore, 0);
    });

    test('penalizes flagged slips heavily', () {
      final clean = usecase.calculate(TruthScoreInput(
        totalScannedSlips: 50,
        verifiedSlips: 45,
        consistentSlips: 44,
        rejectedSlips: 0,
        flaggedSlips: 0,
        lastScanDate: DateTime.now(),
      ));

      final flagged = usecase.calculate(TruthScoreInput(
        totalScannedSlips: 50,
        verifiedSlips: 45,
        consistentSlips: 44,
        rejectedSlips: 5,
        flaggedSlips: 10,
        lastScanDate: DateTime.now(),
      ));

      expect(flagged.truthScore, lessThan(clean.truthScore));
      expect(flagged.breakdown.flagPenalty, greaterThan(0));
    });

    test('recency score decays over time', () {
      final recent = usecase.calculate(TruthScoreInput(
        totalScannedSlips: 50,
        verifiedSlips: 50,
        consistentSlips: 50,
        rejectedSlips: 0,
        flaggedSlips: 0,
        lastScanDate: DateTime.now().subtract(const Duration(days: 1)),
      ));

      final stale = usecase.calculate(TruthScoreInput(
        totalScannedSlips: 50,
        verifiedSlips: 50,
        consistentSlips: 50,
        rejectedSlips: 0,
        flaggedSlips: 0,
        lastScanDate: DateTime.now().subtract(const Duration(days: 45)),
      ));

      expect(stale.breakdown.recencyScore, lessThan(recent.breakdown.recencyScore));
    });

    test('score is clamped between 0 and 100', () {
      final result = usecase.calculate(TruthScoreInput(
        totalScannedSlips: 100,
        verifiedSlips: 0,
        consistentSlips: 0,
        rejectedSlips: 50,
        flaggedSlips: 50,
        lastScanDate: DateTime.now().subtract(const Duration(days: 100)),
      ));

      expect(result.truthScore, greaterThanOrEqualTo(0));
      expect(result.truthScore, lessThanOrEqualTo(100));
    });
  });
}
```

### Bet Slip Parser Tests

```dart
// test/features/verification/data/bet9ja_parser_test.dart
void main() {
  late Bet9jaParser parser;

  setUp(() {
    parser = Bet9jaParser();
  });

  group('Bet9jaParser', () {
    test('detects Bet9ja slip from raw OCR text', () {
      final rawText = File('test/fixtures/ocr/bet9ja_single_bet.txt')
          .readAsStringSync();
      expect(parser.canParse(rawText), isTrue);
    });

    test('does not match non-Bet9ja text', () {
      expect(parser.canParse('SportyBet ticket #12345'), isFalse);
    });

    test('extracts booking code', () {
      final rawText = 'Bet9ja B9J-7K2X4 Arsenal vs Chelsea Home 1.85';
      final result = parser.parse(rawText);
      expect(result.slipCode, 'B9J-7K2X4');
    });

    test('extracts multiple selections from accumulator', () {
      final rawText = File('test/fixtures/ocr/bet9ja_accumulator.txt')
          .readAsStringSync();
      final result = parser.parse(rawText);

      expect(result.bets.length, greaterThan(1));
      for (final bet in result.bets) {
        expect(bet.matchDescription, isNotEmpty);
        expect(bet.odds, greaterThan(0));
      }
    });

    test('handles OCR noise in odds (l vs 1)', () {
      final rawText = 'Arsenal vs Chelsea Home l.85 Stake: 1,000';
      final result = parser.parse(rawText);
      expect(result.bets.first.odds, closeTo(1.85, 0.01));
    });
  });
}
```

### Fraud Detection Tests

```dart
// test/features/verification/domain/usecases/flag_suspicious_slip_test.dart
void main() {
  late FraudDetectionService service;

  setUp(() {
    service = FraudDetectionService();
  });

  group('FraudDetectionService', () {
    test('flags duplicate images', () {
      // Submit same image hash twice
      final slip = FakeData.scannedSlip();
      final imageFile = FakeData.testImage();

      // First submission: no flag
      final flags1 = service.analyze(slip, imageFile);
      expect(flags1, isNot(contains(FraudFlag.duplicateImage)));

      // Second submission with same hash: flagged
      final flags2 = service.analyze(slip.copyWith(id: 'new_id'), imageFile);
      expect(flags2, contains(FraudFlag.duplicateImage));
    });

    test('flags unrealistically high odds', () {
      final slip = FakeData.scannedSlip(
        extractedBets: [FakeData.extractedBet(odds: 100.0)],
      );
      final flags = service.analyze(slip, FakeData.testImage());
      expect(flags, contains(FraudFlag.unrealisticOdds));
    });

    test('flags low OCR confidence', () {
      final slip = FakeData.scannedSlip(ocrConfidence: 0.3);
      final flags = service.analyze(slip, FakeData.testImage());
      expect(flags, contains(FraudFlag.lowOcrConfidence));
    });

    test('does not flag clean slips', () {
      final slip = FakeData.scannedSlip(
        ocrConfidence: 0.95,
        extractedBets: [FakeData.extractedBet(odds: 2.50)],
      );
      final flags = service.analyze(slip, FakeData.testImage());
      expect(flags, isEmpty);
    });
  });
}
```

---

## Test Fixtures (Sample JSON)

```json
// test/fixtures/thesportsdb/upcoming_events.json
{
  "events": [
    {
      "idEvent": "1234567",
      "strEvent": "Arsenal vs Chelsea",
      "strHomeTeam": "Arsenal",
      "strAwayTeam": "Chelsea",
      "strLeague": "English Premier League",
      "dateEvent": "2025-04-20",
      "strTime": "15:00:00",
      "strVenue": "Emirates Stadium",
      "strHomeTeamBadge": "https://...",
      "strAwayTeamBadge": "https://...",
      "intHomeScore": null,
      "intAwayScore": null
    }
  ]
}
```

---

## Integration Tests

```dart
// integration_test/diary_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full diary flow: search → log match → view in diary', (tester) async {
    await tester.pumpWidget(const MatchLogApp());
    await tester.pumpAndSettle();

    // 1. Navigate to diary
    await tester.tap(find.byIcon(Icons.book));
    await tester.pumpAndSettle();

    // 2. Tap FAB to log match
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // 3. Search for a team
    await tester.enterText(find.byType(TextField), 'Arsenal');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 4. Select a fixture
    await tester.tap(find.text('Arsenal vs Chelsea').first);
    await tester.pumpAndSettle();

    // 5. Rate the match
    await tester.tap(find.byIcon(Icons.star).at(3)); // 4 stars
    await tester.pumpAndSettle();

    // 6. Select watch type
    await tester.tap(find.text('TV'));
    await tester.pumpAndSettle();

    // 7. Submit
    await tester.tap(find.text('Log Match'));
    await tester.pumpAndSettle();

    // 8. Verify diary shows the new entry
    expect(find.text('Arsenal vs Chelsea'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsWidgets);
  });
}
```

---

## CI Test Commands

```bash
# Unit + Widget tests
flutter test

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Integration tests (requires device/emulator)
flutter test integration_test/

# Run specific test file
flutter test test/features/diary/domain/usecases/calculate_stats_test.dart

# Run tests matching a pattern
flutter test --name "calculates correct win rate"
```

---

## Coverage Targets

| Phase | Target | Focus |
|-------|--------|-------|
| **Phase 1** | 70% overall, 90%+ domain layer | All usecases must be tested. All entity computed properties tested. |
| **Phase 2** | 70% overall | Social layer usecases + group logic |
| **Phase 3** | 75% overall | AI service response parsing, prediction scoring |
| **Phase 4** | 80% overall (Spring Boot tests added) | Spring Boot: Controller tests, Service tests, Repository tests |

### What MUST Be Tested

- ✅ Every usecase
- ✅ Every repository implementation (online + offline paths)
- ✅ All Drift DAO operations
- ✅ All entity computed properties (ROI, win rate, profit/loss)
- ✅ All formatters and validators
- ✅ API response parsing (with fixture JSON files)
- ✅ SyncQueue enqueue → replay cycle
- ✅ OCR parser accuracy (per-bookmaker with fixture text files)
- ✅ Truth Score computation (all weight factors and edge cases)
- ✅ Fraud detection heuristics (each flag type independently)

### What CAN Skip Tests

- ⬜ Pure UI layout (colors, padding) — visual regression caught in review
- ⬜ Generated code (Freezed, Drift, Riverpod)
- ⬜ Firebase SDK calls — mocked at the data source boundary
