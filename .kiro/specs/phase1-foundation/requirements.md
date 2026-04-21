# Requirements Document

## Introduction

Phase 1 Foundation Setup establishes the complete infrastructure layer for the MatchLog Flutter app — a social sports diary and betting tracker (Letterboxd meets Strava, but for football). This phase fills all empty stub files under `lib/` with production-ready implementations across three layers:

1. **Design system** — FPL-inspired dark theme, Inter + JetBrains Mono typography, spacing tokens, and a fully wired `ThemeData`
2. **Core infrastructure** — environment config (staging/prod), GoRouter navigation skeleton, Riverpod DI providers, and utility classes
3. **Drift database** — all 11 SQLite tables, 4 DAOs, type converters, and the offline sync queue

The app is offline-first (all writes go to Drift first, sync to Firebase when online), dark-mode-first, and sport-agnostic from day one.

### File-Level Descriptions

Every file in this phase carries a top-of-file doc comment explaining its purpose, the user story it serves, and any key design decisions. This ensures future contributors understand the "why" without reading the full spec.

| File | Purpose |
|------|---------|
| `core/theme/colors.dart` | Single source of truth for all app colors. FPL-inspired dark palette. Never hardcode hex values elsewhere. |
| `core/theme/typography.dart` | All text styles using Google Fonts Inter (UI) and JetBrains Mono (odds). Ensures consistent premium typography. |
| `core/theme/spacing.dart` | Named spacing and radius constants on a 4pt grid. Use these instead of raw doubles in widgets. |
| `core/theme/app_theme.dart` | Assembles the full `ThemeData` from colors, typography, and spacing. The single place to change the app's visual identity. |
| `core/config/app_config.dart` | Reads `--dart-define` build flags. Exposes environment (staging/prod), API keys, and base URLs. |
| `core/config/backend_config.dart` | `BackendType` enum (firebase/spring). Controls which data source implementations are active. |
| `core/config/feature_flags.dart` | Runtime feature toggles. Allows disabling in-progress features without a new app release. |
| `core/router/routes.dart` | Named route string constants. Import this instead of typing route strings inline. |
| `core/router/app_router.dart` | GoRouter instance with all Phase 1 routes. Handles unknown routes and deep link entry points. |
| `core/router/deep_link_handler.dart` | Stub for App Links / Universal Links. Wired up in Phase 2 when Bookie Group invite links are added. |
| `core/di/providers.dart` | Core Riverpod providers (database, connectivity, backend config, sync queue). App-wide singletons. |
| `core/di/service_locator.dart` | Ordered initialization sequence: Flutter bindings → Firebase → AppConfig → runApp. |
| `core/utils/formatters.dart` | Currency (₦/$/£), odds (2 d.p.), and date (relative + full) formatters. Used across diary, betting, and stats screens. |
| `core/utils/validators.dart` | Form validation functions for required fields, email, odds, stake, and rating. Returns error string or null. |
| `core/utils/extensions.dart` | Dart extension methods on String, num, and DateTime. Keeps widget code concise. |
| `core/database/type_converters.dart` | Drift type converters for JSON lists/maps and all domain enums. Required before any table can use custom types. |
| `core/database/app_database.dart` | The Drift `GeneratedDatabase` with all 11 tables. The single source of truth for the local SQLite schema. |
| `core/database/daos/match_dao.dart` | Typed queries for `MatchEntries`. Used by the diary repository. |
| `core/database/daos/bet_dao.dart` | Typed queries for `BetEntries`. Used by the betting repository. |
| `core/database/daos/group_dao.dart` | Typed queries for `BookieGroups` and `GroupMembers`. Used by the groups repository. |
| `core/database/daos/prediction_dao.dart` | Typed queries for `Predictions`. Used by the predictions repository. |
| `app.dart` | Root `MatchLogApp` widget. Wires GoRouter + AppTheme.dark into `MaterialApp.router`. |
| `main.dart` | Entry point. Initializes Firebase, AppConfig, then calls `runApp` with `ProviderScope`. |

---

## Glossary

- **App**: The MatchLog Flutter application.
- **AppConfig**: The singleton that reads `--dart-define` environment variables and exposes them to the rest of the app.
- **AppDatabase**: The Drift `GeneratedDatabase` class that owns all SQLite tables and DAOs.
- **AppRouter**: The `GoRouter` instance that owns all named routes and navigation logic.
- **AppTheme**: The class that exposes the `ThemeData` used by `MaterialApp`.
- **BackendConfig**: The configuration object that selects between Firebase and Spring Boot backends.
- **BetDao**: The Drift DAO responsible for all `BetEntries` table queries.
- **BetEntries**: The Drift table storing local bet log records.
- **BookieGroups**: The Drift table storing local bookie group records.
- **CurrencyFormatter**: The utility class that formats monetary amounts with locale-aware symbols.
- **DateFormatter**: The utility class that formats `DateTime` values into human-readable strings.
- **FeatureFlags**: The class that holds runtime feature toggle values.
- **FixtureCache**: The Drift table that caches API fixture responses with expiry timestamps.
- **GroupDao**: The Drift DAO responsible for all `BookieGroups` and `GroupMembers` table queries.
- **GroupMembers**: The Drift table storing group membership records.
- **MatchDao**: The Drift DAO responsible for all `MatchEntries` table queries.
- **MatchEntries**: The Drift table storing local match diary records.
- **MatchLogApp**: The root `StatelessWidget` that wires `GoRouter`, `AppTheme.dark`, and `ProviderScope`.
- **MatchLogColors**: The class holding all FPL-inspired color constants.
- **MatchLogSpacing**: The class holding all spacing and radius constants.
- **MatchLogTypography**: The class holding all `TextStyle` definitions using Google Fonts Inter and JetBrains Mono.
- **OddsFormatter**: The utility class that formats decimal odds values for display.
- **PredictionDao**: The Drift DAO responsible for all `Predictions` table queries.
- **Predictions**: The Drift table storing local prediction records.
- **ProviderScope**: The Riverpod root widget that owns all provider state.
- **ScannedBetSlips**: The Drift table storing OCR-scanned bet slip records.
- **ServiceLocator**: The class that runs the ordered app initialization sequence before `runApp`.
- **SyncQueue**: The Drift table that queues pending offline operations for replay when connectivity is restored.
- **TruthScores**: The Drift table caching computed truth score records per user.
- **TypeConverter**: A Drift `TypeConverter` that maps between Dart types and SQLite column types.
- **UserProfiles**: The Drift table storing local user profile records.
- **Validator**: A utility function or class in `validators.dart` that returns an error string or `null`.

---

## Requirements

### Requirement 1: Design System — Colors

**User Story:** As a developer, I want a single source of truth for all app colors, so that every widget uses the correct FPL-inspired palette without hardcoding hex values.

#### Acceptance Criteria

1. THE `MatchLogColors` class SHALL define `background` as `Color(0xFF0E0B16)`.
2. THE `MatchLogColors` class SHALL define `surface` as `Color(0xFF1A1625)`.
3. THE `MatchLogColors` class SHALL define `surfaceElevated` as `Color(0xFF241F31)`.
4. THE `MatchLogColors` class SHALL define `surfaceBorder` as `Color(0xFF2D2640)`.
5. THE `MatchLogColors` class SHALL define `primary` as `Color(0xFFE90052)`.
6. THE `MatchLogColors` class SHALL define `secondary` as `Color(0xFF963CFF)`.
7. THE `MatchLogColors` class SHALL define `success` as `Color(0xFF00DC82)`.
8. THE `MatchLogColors` class SHALL define `error` as `Color(0xFFFF4D6A)`.
9. THE `MatchLogColors` class SHALL define `warning` as `Color(0xFFFFB800)`.
10. THE `MatchLogColors` class SHALL define `textPrimary`, `textSecondary`, `textTertiary`, and `textDisabled` text color constants.
11. THE `MatchLogColors` class SHALL define sport-specific accent constants: `footballAccent`, `basketballAccent`, `f1Accent`, `mmaAccent`, `cricketAccent`, and `tennisAccent`.
12. THE `MatchLogColors` class SHALL define surface-tint variants: `primarySurface`, `secondarySurface`, `successSurface`, `errorSurface`, and `warningSurface`.

---

### Requirement 2: Design System — Typography

**User Story:** As a developer, I want all text styles defined in one place using Google Fonts, so that the app has consistent, premium typography throughout.

#### Acceptance Criteria

1. THE `MatchLogTypography` class SHALL define `headlineXL` using `GoogleFonts.inter` at `fontSize: 32`, `fontWeight: FontWeight.w800`.
2. THE `MatchLogTypography` class SHALL define `headlineLarge`, `headlineMedium`, and `headlineSmall` using `GoogleFonts.inter` with decreasing sizes and appropriate weights.
3. THE `MatchLogTypography` class SHALL define `bodyLarge`, `bodyMedium`, and `bodySmall` using `GoogleFonts.inter` with `color: MatchLogColors.textSecondary` or `textTertiary`.
4. THE `MatchLogTypography` class SHALL define `labelLarge` and `labelSmall` using `GoogleFonts.inter` with `fontWeight: FontWeight.w600` and `FontWeight.w500` respectively.
5. THE `MatchLogTypography` class SHALL define `statNumber` using `GoogleFonts.inter` at `fontSize: 36`, `fontWeight: FontWeight.w900`.
6. THE `MatchLogTypography` class SHALL define `oddsDisplay` using `GoogleFonts.jetBrainsMono` at `fontSize: 16`, `fontWeight: FontWeight.w600`, `color: MatchLogColors.primary`.

---

### Requirement 3: Design System — Spacing

**User Story:** As a developer, I want a set of named spacing constants, so that padding, margins, and border radii are consistent across all screens.

#### Acceptance Criteria

1. THE `MatchLogSpacing` class SHALL define scalar constants `xs = 4.0`, `sm = 8.0`, `md = 12.0`, `lg = 16.0`, `xl = 24.0`, `xxl = 32.0`, and `xxxl = 48.0`.
2. THE `MatchLogSpacing` class SHALL define `screenPadding` as `EdgeInsets.symmetric(horizontal: 16.0)`.
3. THE `MatchLogSpacing` class SHALL define `cardPadding` as `EdgeInsets.all(16.0)` and `cardPaddingCompact` as `EdgeInsets.all(12.0)`.
4. THE `MatchLogSpacing` class SHALL define border radius constants `radiusSm = 8.0`, `radiusMd = 12.0`, `radiusLg = 16.0`, `radiusXl = 24.0`, and `radiusFull = 100.0`.

---

### Requirement 4: Design System — AppTheme

**User Story:** As a developer, I want a fully wired `ThemeData` object, so that every Material widget automatically uses the MatchLog design system without per-widget overrides.

#### Acceptance Criteria

1. THE `AppTheme` class SHALL expose a static `dark` getter that returns a `ThemeData` with `brightness: Brightness.dark`.
2. THE `AppTheme.dark` getter SHALL set `scaffoldBackgroundColor` to `MatchLogColors.background`.
3. THE `AppTheme.dark` getter SHALL configure `ColorScheme.dark` with `primary`, `secondary`, `surface`, and `error` values from `MatchLogColors`.
4. THE `AppTheme.dark` getter SHALL configure `AppBarTheme` with zero elevation, `backgroundColor: MatchLogColors.background`, and `titleTextStyle: MatchLogTypography.headlineMedium`.
5. THE `AppTheme.dark` getter SHALL configure `CardTheme` with `color: MatchLogColors.surface`, zero elevation, and a `RoundedRectangleBorder` using `MatchLogSpacing.radiusMd` and `MatchLogColors.surfaceBorder`.
6. THE `AppTheme.dark` getter SHALL configure `ElevatedButtonThemeData` with `backgroundColor: MatchLogColors.primary`, `foregroundColor: Colors.white`, and shape using `MatchLogSpacing.radiusMd`.
7. THE `AppTheme.dark` getter SHALL configure `InputDecorationTheme` with `fillColor: MatchLogColors.surfaceElevated`, focused border in `MatchLogColors.primary`, and error border in `MatchLogColors.error`.
8. THE `AppTheme.dark` getter SHALL configure `BottomNavigationBarThemeData` with `backgroundColor: MatchLogColors.surface`, `selectedItemColor: MatchLogColors.primary`, and `unselectedItemColor: MatchLogColors.textTertiary`.
9. THE `AppTheme.dark` getter SHALL configure `ChipTheme`, `DividerTheme`, and `DialogTheme` using the corresponding `MatchLogColors` and `MatchLogSpacing` values.

---

### Requirement 5: Environment Configuration

**User Story:** As a developer, I want the app to read its configuration from `--dart-define` flags at build time, so that staging and production environments can be selected without code changes.

#### Acceptance Criteria

1. THE `AppConfig` class SHALL define an `Environment` enum with values `staging` and `prod` only.
2. THE `AppConfig` class SHALL expose a `factory AppConfig.fromEnvironment()` constructor that reads `ENV`, `FOOTBALL_API_KEY`, `FOOTBALL_API_URL`, and `GEMINI_API_KEY` from `String.fromEnvironment`.
3. WHEN `ENV` is not provided or is unrecognized, THE `AppConfig` SHALL default `environment` to `Environment.staging`.
4. WHEN `FOOTBALL_API_URL` is not provided, THE `AppConfig` SHALL default `footballApiBaseUrl` to `'https://www.thesportsdb.com/api/v1/json'`.
5. THE `AppConfig` class SHALL expose a static `late AppConfig instance` field that is assigned during app initialization before `runApp`.
6. THE `BackendConfig` class SHALL define a `BackendType` enum with values `firebase` and `spring`.
7. THE `FeatureFlags` class SHALL define boolean flag fields for toggling features at runtime, with all flags defaulting to `false` unless explicitly enabled.
8. THE `AppRouter` SHALL configure `GoRouter` with `debugLogDiagnostics: true` in `staging` environment and `false` in `prod`.

---

### Requirement 6: Routing

**User Story:** As a developer, I want a centralized GoRouter configuration with named route constants, so that navigation is type-safe and deep links can be handled consistently.

#### Acceptance Criteria

1. THE `routes.dart` file SHALL define a `Routes` class with string constants for every named route in Phase 1: `home`, `diary`, `logMatch`, `matchDetail`, `betting`, `logBet`, `stats`, `profile`, and `settings`.
2. THE `AppRouter` class SHALL expose a static `GoRouter router` instance configured with the route constants from `routes.dart`.
3. WHEN a route is not found, THE `AppRouter` SHALL redirect to the `home` route.
4. THE `deep_link_handler.dart` file SHALL define a `DeepLinkHandler` stub class with a `handle(Uri uri)` method that returns `void`, ready for Phase 2 Bookie Group invite link implementation.

---

### Requirement 7: Dependency Injection

**User Story:** As a developer, I want all core Riverpod providers defined in one place, so that any widget or use case can access shared infrastructure without manual instantiation.

#### Acceptance Criteria

1. THE `providers.dart` file SHALL define a `connectivityProvider` that exposes a `ConnectivityResult` stream using `connectivity_plus`.
2. THE `providers.dart` file SHALL define an `appDatabaseProvider` that exposes a singleton `AppDatabase` instance.
3. THE `providers.dart` file SHALL define a `backendConfigProvider` that exposes the active `BackendConfig`.
4. THE `providers.dart` file SHALL define a `syncQueueProvider` that exposes access to the `SyncQueue` table via the `AppDatabase`.
5. THE `ServiceLocator` class SHALL define an `initialize()` static method that calls `WidgetsFlutterBinding.ensureInitialized()`, `Firebase.initializeApp()`, and `AppConfig.fromEnvironment()` in the correct order before `runApp` is called.

---

### Requirement 8: Drift Database — Type Converters

**User Story:** As a developer, I want Drift type converters for all custom Dart types, so that enums and JSON structures are stored and retrieved correctly from SQLite.

#### Acceptance Criteria

1. THE `type_converters.dart` file SHALL define a `JsonListConverter` that maps between `List<dynamic>` and a `TEXT` SQLite column using `jsonEncode`/`jsonDecode`.
2. THE `type_converters.dart` file SHALL define a `JsonMapConverter` that maps between `Map<String, dynamic>` and a `TEXT` SQLite column using `jsonEncode`/`jsonDecode`.
3. THE `type_converters.dart` file SHALL define `intEnum` converters (or use Drift's built-in `intEnum`) for `Sport`, `WatchType`, `BetType`, `BetVisibility`, `UserTier`, `GroupPrivacy`, `GroupRole`, `PredictionConfidence`, `VerificationStatus`, and `TruthTier`.
4. WHEN a `JsonListConverter` encodes a `null` list, THE converter SHALL produce the string `'[]'`.
5. WHEN a `JsonMapConverter` encodes a `null` map, THE converter SHALL produce the string `'{}'`.

---

### Requirement 9: Drift Database — Tables

**User Story:** As a developer, I want all Drift table definitions in a single database file, so that the SQLite schema is the single source of truth for local persistence.

#### Acceptance Criteria

1. THE `AppDatabase` class SHALL include the `MatchEntries` table with columns: `id` (TEXT PK), `userId`, `sport` (intEnum), `fixtureId`, `homeTeam`, `awayTeam` (nullable), `score`, `league`, `watchType` (intEnum), `rating` (1–5 check), `review` (nullable), `photos` (JsonList), `venue` (nullable), `sportMetadata` (JsonMap), `geoVerified` (bool, default false), `createdAt`, `updatedAt` (nullable), `synced` (bool, default false).
2. THE `AppDatabase` class SHALL include the `BetEntries` table with columns: `id` (TEXT PK), `userId`, `sport` (intEnum), `fixtureId`, `matchDescription`, `betType` (intEnum), `prediction`, `odds` (real), `stake` (real), `currency` (default `'NGN'`), `bookmaker`, `settled` (bool, default false), `won` (nullable bool), `payout` (nullable real), `settledAt` (nullable), `visibility` (intEnum), `createdAt`, `synced` (bool, default false).
3. THE `AppDatabase` class SHALL include the `BookieGroups` table with columns: `id` (TEXT PK), `name`, `adminId`, `privacy` (intEnum), `inviteCode` (unique), `leagueFocus` (nullable JsonList), `sportFocus` (nullable intEnum), `memberCount` (default 0), `createdAt`, `synced` (bool, default false).
4. THE `AppDatabase` class SHALL include the `GroupMembers` table with composite PK `(groupId, userId)`, columns: `groupId` (FK → BookieGroups), `userId`, `role` (intEnum), `totalPredictions` (default 0), `correctPredictions` (default 0), `winRate` (real, default 0.0), `joinedAt`.
5. THE `AppDatabase` class SHALL include the `Predictions` table with columns: `id` (TEXT PK), `userId`, `groupId` (nullable FK), `fixtureId`, `matchDescription`, `prediction`, `confidence` (intEnum), `settled` (bool, default false), `correct` (nullable bool), `points` (nullable int), `kickoffAt`, `createdAt`, `synced` (bool, default false).
6. THE `AppDatabase` class SHALL include the `Follows` table with composite PK `(followerId, followingId)` and `createdAt`.
7. THE `AppDatabase` class SHALL include the `UserProfiles` table with PK `userId` and columns: `displayName`, `email`, `photoUrl` (nullable), `tier` (intEnum), `favoriteSport` (nullable intEnum), `favoriteTeam` (nullable), `followerCount` (default 0), `followingCount` (default 0), `createdAt`.
8. THE `AppDatabase` class SHALL include the `SyncQueue` table with auto-increment `id`, columns: `operation`, `collection`, `documentId`, `payload` (JSON string), `retryCount` (default 0), `completed` (bool, default false), `failed` (bool, default false), `createdAt`.
9. THE `AppDatabase` class SHALL include the `FixtureCache` table with PK `fixtureId`, columns: `teamId` (nullable), `data` (JSON string), `cachedAt`, `expiresAt`.
10. THE `AppDatabase` class SHALL include the `ScannedBetSlips` table with PK `id` and all columns defined in `DATA_MODELS.md`, including `synced` (bool, default false).
11. THE `AppDatabase` class SHALL include the `TruthScores` table with PK `userId` and all columns defined in `DATA_MODELS.md`.
12. THE `AppDatabase` class SHALL be annotated with `@DriftDatabase` listing all eleven tables.

---

### Requirement 10: Drift Database — DAOs

**User Story:** As a developer, I want typed DAO classes for each domain area, so that database queries are encapsulated and testable in isolation.

#### Acceptance Criteria

1. THE `MatchDao` class SHALL be annotated with `@DriftAccessor(tables: [MatchEntries])` and provide: `insertMatch`, `updateMatch`, `deleteMatch`, `watchAllMatches(String userId)`, `getMatchesByUser(String userId)`, and `getUnsyncedMatches()`.
2. THE `BetDao` class SHALL be annotated with `@DriftAccessor(tables: [BetEntries])` and provide: `insertBet`, `updateBet`, `deleteBet`, `watchBetsByUser(String userId)`, `getUnsettledBets(String userId)`, and `getUnsyncedBets()`.
3. THE `GroupDao` class SHALL be annotated with `@DriftAccessor(tables: [BookieGroups, GroupMembers])` and provide: `insertGroup`, `updateGroup`, `getGroupById(String id)`, `watchGroupsForUser(String userId)`, `insertMember`, `getMembersForGroup(String groupId)`, and `getUnsyncedGroups()`.
4. THE `PredictionDao` class SHALL be annotated with `@DriftAccessor(tables: [Predictions])` and provide: `insertPrediction`, `updatePrediction`, `watchPredictionsForGroup(String groupId)`, `getUnsettledPredictions(String userId)`, and `getUnsyncedPredictions()`.
5. WHEN `getUnsyncedMatches()` is called, THE `MatchDao` SHALL return only rows where `synced = false`.
6. WHEN `getUnsyncedBets()` is called, THE `BetDao` SHALL return only rows where `synced = false`.

---

### Requirement 11: Utility — Formatters

**User Story:** As a developer, I want reusable formatter utilities, so that currency, odds, and date values are displayed consistently across all screens.

#### Acceptance Criteria

1. THE `CurrencyFormatter` class SHALL expose a `format(double amount, String currency)` method that returns a locale-aware string (e.g., `'₦1,000.00'` for NGN, `'$1,000.00'` for USD).
2. THE `OddsFormatter` class SHALL expose a `format(double odds)` method that returns a string with exactly two decimal places (e.g., `'2.10'`).
3. THE `DateFormatter` class SHALL expose a `formatRelative(DateTime date)` method that returns `'Today'`, `'Yesterday'`, or a formatted date string for older dates.
4. THE `DateFormatter` class SHALL expose a `formatFull(DateTime date)` method that returns a string in the format `'Apr 15, 2025'`.
5. WHEN `CurrencyFormatter.format` is called with an unrecognized currency code, THE `CurrencyFormatter` SHALL prepend the raw currency code as a prefix (e.g., `'XYZ 1,000.00'`).

---

### Requirement 12: Utility — Validators

**User Story:** As a developer, I want form validation functions, so that user input is validated consistently before submission.

#### Acceptance Criteria

1. THE `Validators` class SHALL expose a `required(String? value)` method that returns a non-null error string when `value` is null or empty, and `null` when valid.
2. THE `Validators` class SHALL expose a `email(String? value)` method that returns a non-null error string when `value` does not match a valid email pattern, and `null` when valid.
3. THE `Validators` class SHALL expose a `odds(String? value)` method that returns a non-null error string when `value` cannot be parsed as a `double` greater than `1.0`, and `null` when valid.
4. THE `Validators` class SHALL expose a `stake(String? value)` method that returns a non-null error string when `value` cannot be parsed as a positive `double`, and `null` when valid.
5. THE `Validators` class SHALL expose a `rating(int? value)` method that returns a non-null error string when `value` is not between 1 and 5 inclusive, and `null` when valid.
6. WHEN `Validators.email` receives an empty string, THE `Validators` SHALL return the same error as `Validators.required`.

---

### Requirement 13: Utility — Extensions

**User Story:** As a developer, I want Dart extension methods on common types, so that repetitive transformations are concise and readable throughout the codebase.

#### Acceptance Criteria

1. THE `StringExtensions` extension on `String` SHALL provide an `isNullOrEmpty` getter (or equivalent on `String?`) that returns `true` when the string is null or has zero length after trimming.
2. THE `StringExtensions` extension on `String` SHALL provide a `capitalize()` method that returns the string with its first character uppercased.
3. THE `NumExtensions` extension on `num` SHALL provide a `toCurrency(String currency)` method that delegates to `CurrencyFormatter.format`.
4. THE `DateTimeExtensions` extension on `DateTime` SHALL provide a `isToday` getter that returns `true` when the date matches the current calendar day.
5. THE `DateTimeExtensions` extension on `DateTime` SHALL provide a `isYesterday` getter that returns `true` when the date matches the previous calendar day.
6. THE `DateTimeExtensions` extension on `DateTime` SHALL provide a `toRelativeString()` method that delegates to `DateFormatter.formatRelative`.

---

### Requirement 14: Entry Point — app.dart

**User Story:** As a developer, I want a clean root widget that wires the router and theme, so that the app boots into the correct initial state with all infrastructure in place.

#### Acceptance Criteria

1. THE `MatchLogApp` widget SHALL be a `StatelessWidget` that returns a `MaterialApp.router`.
2. THE `MatchLogApp` widget SHALL pass `AppRouter.router` as the `routerConfig` parameter.
3. THE `MatchLogApp` widget SHALL pass `AppTheme.dark` as the `theme` parameter.
4. THE `MatchLogApp` widget SHALL set `debugShowCheckedModeBanner: false`.
5. THE `MatchLogApp` widget SHALL set `title: 'MatchLog'`.

---

### Requirement 15: Entry Point — main.dart

**User Story:** As a developer, I want a clean `main()` function that initializes all services in the correct order, so that the app never starts with uninitialized dependencies.

#### Acceptance Criteria

1. THE `main()` function SHALL call `WidgetsFlutterBinding.ensureInitialized()` as its first statement.
2. THE `main()` function SHALL call `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` before `runApp`.
3. THE `main()` function SHALL call `AppConfig.fromEnvironment()` and assign the result to `AppConfig.instance` before `runApp`.
4. THE `main()` function SHALL call `runApp` with a `ProviderScope` wrapping `MatchLogApp`.
5. WHEN `Firebase.initializeApp` throws an exception, THE `main()` function SHALL rethrow the exception so it surfaces as a fatal startup error rather than a silent failure.

---

### Requirement 16: Offline-First Sync Queue

**User Story:** As a developer, I want the SyncQueue table and its access patterns defined, so that offline write operations can be enqueued and replayed when connectivity is restored.

#### Acceptance Criteria

1. THE `SyncQueue` table SHALL store each pending operation with fields: `operation` (create/update/delete), `collection`, `documentId`, `payload` (JSON), `retryCount`, `completed`, `failed`, and `createdAt`.
2. WHEN a sync operation is enqueued, THE `AppDatabase` SHALL insert a new row into `SyncQueue` with `completed = false`, `failed = false`, and `retryCount = 0`.
3. WHEN `getPendingOperations()` is called on the `SyncQueue`, THE `AppDatabase` SHALL return only rows where `completed = false` AND `failed = false`, ordered by `createdAt` ascending.
4. WHEN `markCompleted(int id)` is called, THE `AppDatabase` SHALL update the matching row to set `completed = true`.
5. WHEN `incrementRetry(int id)` is called and `retryCount` reaches 3, THE `AppDatabase` SHALL set `failed = true` on the matching row.
6. FOR ALL valid `SyncOperation` payloads, encoding then decoding the `payload` JSON SHALL produce an equivalent map (round-trip property).

---

### Requirement 17: Fixture Cache

**User Story:** As a developer, I want the FixtureCache table to store API responses with expiry timestamps, so that the app can serve fixture data offline without redundant network calls.

#### Acceptance Criteria

1. THE `FixtureCache` table SHALL store `fixtureId` (PK), `teamId` (nullable), `data` (full JSON response string), `cachedAt`, and `expiresAt`.
2. WHEN `getCachedFixture(String fixtureId)` is called and a row exists with `expiresAt` in the future, THE `AppDatabase` SHALL return the cached row.
3. WHEN `getCachedFixture(String fixtureId)` is called and the row's `expiresAt` is in the past, THE `AppDatabase` SHALL return `null` (treating the cache as a miss).
4. WHEN `upsertFixture` is called with an existing `fixtureId`, THE `AppDatabase` SHALL replace the existing row.

---

### Requirement 18: Testing — Formatters and Validators

**User Story:** As a developer, I want unit tests for all formatters and validators, so that regressions in formatting or validation logic are caught immediately.

#### Acceptance Criteria

1. THE formatter tests SHALL verify that `CurrencyFormatter.format(1000.0, 'NGN')` returns `'₦1,000.00'`.
2. THE formatter tests SHALL verify that `OddsFormatter.format(2.1)` returns `'2.10'`.
3. THE formatter tests SHALL verify that `DateFormatter.formatRelative` returns `'Today'` for `DateTime.now()`.
4. THE validator tests SHALL verify that `Validators.required(null)` returns a non-null string.
5. THE validator tests SHALL verify that `Validators.email('not-an-email')` returns a non-null string.
6. THE validator tests SHALL verify that `Validators.odds('0.9')` returns a non-null string (odds must be > 1.0).
7. THE validator tests SHALL verify that `Validators.rating(6)` returns a non-null string.
8. THE validator tests SHALL verify that `Validators.required('hello')` returns `null`.

---

### Requirement 19: Testing — Drift DAOs

**User Story:** As a developer, I want Drift DAO tests using an in-memory database, so that all query logic is verified without touching the file system.

#### Acceptance Criteria

1. THE DAO tests SHALL construct `AppDatabase` using `NativeDatabase.memory()` for isolation.
2. THE `MatchDao` tests SHALL verify that `insertMatch` followed by `getMatchesByUser` returns the inserted row.
3. THE `BetDao` tests SHALL verify that `insertBet` followed by `getUnsettledBets` returns the inserted row when `settled = false`.
4. THE `MatchDao` tests SHALL verify that `getUnsyncedMatches` returns only rows where `synced = false`.
5. THE `GroupDao` tests SHALL verify that `insertGroup` followed by `getGroupById` returns the correct group.
6. THE `PredictionDao` tests SHALL verify that `insertPrediction` followed by `watchPredictionsForGroup` emits the inserted row.

---

### Requirement 20: Testing — SyncQueue Enqueue/Replay Cycle

**User Story:** As a developer, I want tests for the SyncQueue enqueue and replay cycle, so that the offline-first write path is verified end-to-end.

#### Acceptance Criteria

1. WHEN a `SyncOperation` is enqueued, THE test SHALL verify that `getPendingOperations()` returns exactly one row with `completed = false`.
2. WHEN `markCompleted` is called on a pending operation, THE test SHALL verify that `getPendingOperations()` returns zero rows.
3. WHEN `incrementRetry` is called three times on the same operation, THE test SHALL verify that the row has `failed = true`.
4. WHEN multiple operations are enqueued, THE test SHALL verify that `getPendingOperations()` returns them in `createdAt` ascending order.
5. FOR ALL valid JSON payloads inserted into `SyncQueue.payload`, THE test SHALL verify that `jsonDecode(jsonEncode(payload))` produces an equivalent map (round-trip property).
