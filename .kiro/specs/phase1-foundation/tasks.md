# Implementation Tasks: Phase 1 Foundation

## Tasks

- [x] 1. Design System
  - [x] 1.1 Implement `lib/core/theme/colors.dart` — `MatchLogColors` class with all color constants (backgrounds, primary, secondary, semantic, text, sport accents, surface tints)
  - [x] 1.2 Implement `lib/core/theme/typography.dart` — `MatchLogTypography` class using `GoogleFonts.inter` for all UI text and `GoogleFonts.jetBrainsMono` for `oddsDisplay`
  - [x] 1.3 Implement `lib/core/theme/spacing.dart` — `MatchLogSpacing` class with scalar constants, EdgeInsets, and border radius values
  - [x] 1.4 Implement `lib/core/theme/app_theme.dart` — `AppTheme.dark` static getter assembling full `ThemeData` from colors, typography, and spacing

- [x] 2. Environment Configuration
  - [x] 2.1 Implement `lib/core/config/app_config.dart` — `Environment` enum (staging/prod), `AppConfig.fromEnvironment()` factory reading `--dart-define` flags, static `instance` field
  - [x] 2.2 Implement `lib/core/config/backend_config.dart` — `BackendType` enum and `BackendConfig` class
  - [x] 2.3 Implement `lib/core/config/feature_flags.dart` — `FeatureFlags` class with all flags defaulting to false

- [x] 3. Routing
  - [x] 3.1 Implement `lib/core/router/routes.dart` — `Routes` abstract class with all Phase 1 named route string constants
  - [x] 3.2 Implement `lib/core/router/app_router.dart` — `AppRouter` with static `GoRouter router`, all Phase 1 routes pointing to placeholder screens, unknown route redirect to home, `debugLogDiagnostics` tied to staging env
  - [x] 3.3 Implement `lib/core/router/deep_link_handler.dart` — `DeepLinkHandler` stub with `handle(Uri uri)` method

- [x] 4. Dependency Injection
  - [x] 4.1 Implement `lib/core/di/providers.dart` — `appDatabaseProvider`, `connectivityProvider`, `backendConfigProvider` using `@Riverpod(keepAlive: true)`
  - [x] 4.2 Implement `lib/core/di/service_locator.dart` — `ServiceLocator.initialize()` with ordered init: Flutter bindings → Firebase → AppConfig

- [x] 5. Drift Type Converters
  - [x] 5.1 Implement `lib/core/database/type_converters.dart` — `JsonListConverter`, `JsonMapConverter`, and all domain enum definitions (`Sport`, `WatchType`, `BetType`, `BetVisibility`, `UserTier`, `GroupPrivacy`, `GroupRole`, `PredictionConfidence`, `VerificationStatus`, `TruthTier`)

- [x] 6. Drift Database Tables
  - [x] 6.1 Implement all 11 Drift table classes in `lib/core/database/app_database.dart`: `MatchEntries`, `BetEntries`, `BookieGroups`, `GroupMembers`, `Predictions`, `Follows`, `UserProfiles`, `SyncQueue`, `FixtureCache`, `ScannedBetSlips`, `TruthScores`
  - [x] 6.2 Annotate `AppDatabase` with `@DriftDatabase` listing all 11 tables and all 4 DAOs, and implement `openConnection()` using `LazyDatabase`

- [x] 7. Drift DAOs
  - [x] 7.1 Implement `lib/core/database/daos/match_dao.dart` — `MatchDao` with `insertMatch`, `updateMatch`, `deleteMatch`, `watchMatchesByUser`, `getMatchesByUser`, `getUnsyncedMatches`
  - [x] 7.2 Implement `lib/core/database/daos/bet_dao.dart` — `BetDao` with `insertBet`, `updateBet`, `deleteBet`, `watchBetsByUser`, `getUnsettledBets`, `getUnsyncedBets`
  - [x] 7.3 Implement `lib/core/database/daos/group_dao.dart` — `GroupDao` with `insertGroup`, `updateGroup`, `getGroupById`, `watchGroupsForUser`, `insertMember`, `getMembersForGroup`, `getUnsyncedGroups`
  - [x] 7.4 Implement `lib/core/database/daos/prediction_dao.dart` — `PredictionDao` with `insertPrediction`, `updatePrediction`, `watchPredictionsForGroup`, `getUnsettledPredictions`, `getUnsyncedPredictions`

- [x] 8. Utilities
  - [x] 8.1 Implement `lib/core/utils/formatters.dart` — `CurrencyFormatter.format`, `OddsFormatter.format`, `DateFormatter.formatRelative`, `DateFormatter.formatFull`
  - [x] 8.2 Implement `lib/core/utils/validators.dart` — `Validators.required`, `Validators.email`, `Validators.odds`, `Validators.stake`, `Validators.rating`
  - [x] 8.3 Implement `lib/core/utils/extensions.dart` — `StringExtensions` (isNullOrEmpty, capitalize), `NumExtensions` (toCurrency), `DateTimeExtensions` (isToday, isYesterday, toRelativeString)

- [x] 9. Shared Widgets (stubs)
  - [x] 9.1 Implement `lib/shared/widgets/loading_shimmer.dart` — shimmer placeholder matching MatchCard dimensions
  - [x] 9.2 Implement `lib/shared/widgets/empty_state.dart` — centered icon + title + subtitle + optional CTA button
  - [x] 9.3 Implement `lib/shared/widgets/error_state.dart` — icon + message + retry button
  - [x] 9.4 Implement `lib/shared/widgets/app_bar.dart` — custom AppBar using MatchLog theme
  - [x] 9.5 Implement `lib/shared/widgets/bottom_nav.dart` — 4-tab bottom navigation (Diary, Betting, Social, More)
  - [x] 9.6 Implement `lib/shared/widgets/photo_grid.dart` — grid display for match photo lists

- [x] 10. Shared Constants
  - [x] 10.1 Implement `lib/shared/constants/bookmakers.dart` — `kBookmakers` list with Nigerian and international bookmakers
  - [x] 10.2 Implement `lib/shared/constants/leagues.dart` — `kPopularLeagues` list with league names and IDs
  - [x] 10.3 Implement `lib/shared/constants/sports.dart` — sport configuration constants

- [x] 11. Entry Point
  - [x] 11.1 Implement `lib/app.dart` — `MatchLogApp` as `StatelessWidget` returning `MaterialApp.router` with `AppRouter.router`, `AppTheme.dark`, `title: 'MatchLog'`, `debugShowCheckedModeBanner: false`
  - [x] 11.2 Implement `lib/main.dart` — `main()` calling `ServiceLocator.initialize()` then `runApp(ProviderScope(child: MatchLogApp()))`

- [x] 12. Code Generation
  - [x] 12.1 Run `dart run build_runner build --delete-conflicting-outputs` to generate `app_database.g.dart`, all DAO mixin files, and Riverpod provider files. Verify no generation errors.

- [x] 13. Tests — Formatters and Validators
  - [x] 13.1 Write `test/core/utils/formatters_test.dart` — test NGN/USD formatting, odds 2 d.p., relative date (today/yesterday/older)
  - [x] 13.2 Write `test/core/utils/validators_test.dart` — test required (null/empty/valid), email (invalid/valid), odds (≤1.0/valid), stake (negative/valid), rating (0/6/valid)

- [x] 14. Tests — Drift DAOs
  - [x] 14.1 Write `test/core/database/match_dao_test.dart` — insert/get, unsynced filter, watch stream using `NativeDatabase.memory()`
  - [x] 14.2 Write `test/core/database/bet_dao_test.dart` — insert/unsettled filter, unsynced filter
  - [x] 14.3 Write `test/core/database/group_dao_test.dart` — insert group/getById, insert member/getMembers
  - [x] 14.4 Write `test/core/database/prediction_dao_test.dart` — insert/watchForGroup stream emission
  - [x] 14.5 Write `test/core/database/sync_queue_test.dart` — enqueue/getPending, markCompleted, incrementRetry×3→failed, ordering by createdAt, JSON payload round-trip property test
