# Design Document: Phase 1 Foundation

## Overview

This document describes the technical design for the MatchLog Phase 1 Foundation — the complete infrastructure layer that all feature modules depend on. It covers the design system, environment configuration, routing, dependency injection, Drift database schema, and app entry point.

All decisions here are constrained by three principles from the architecture docs:
1. **Offline-first** — Drift is the primary data store; Firebase is a sync target
2. **Sport-agnostic** — enums and schemas support all sports from day one
3. **Swappable backend** — Clean Architecture means `FirebaseDataSource` can be replaced by `SpringDataSource` in Phase 4 without touching presentation

---

## Architecture

### Layer Dependency Rules

```
Presentation  →  Domain  ←  Data
                   ↑
                 Core
```

- `Domain` imports nothing (pure Dart)
- `Data` imports `Domain` only
- `Presentation` imports `Domain` via Riverpod providers
- `Core` imports packages only, never feature modules

### File Structure Being Implemented

```
lib/
├── core/
│   ├── config/
│   │   ├── app_config.dart          # --dart-define reader, Environment enum
│   │   ├── backend_config.dart      # BackendType enum (firebase|spring)
│   │   └── feature_flags.dart       # Runtime feature toggles
│   ├── database/
│   │   ├── app_database.dart        # Drift @DriftDatabase with all 11 tables
│   │   ├── type_converters.dart     # JsonList, JsonMap, intEnum converters
│   │   └── daos/
│   │       ├── match_dao.dart
│   │       ├── bet_dao.dart
│   │       ├── group_dao.dart
│   │       └── prediction_dao.dart
│   ├── di/
│   │   ├── providers.dart           # Core Riverpod providers
│   │   └── service_locator.dart     # Initialization sequence
│   ├── router/
│   │   ├── routes.dart              # Named route constants
│   │   ├── app_router.dart          # GoRouter instance
│   │   └── deep_link_handler.dart   # Phase 2 stub
│   ├── theme/
│   │   ├── colors.dart              # MatchLogColors
│   │   ├── typography.dart          # MatchLogTypography
│   │   ├── spacing.dart             # MatchLogSpacing
│   │   └── app_theme.dart           # AppTheme.dark ThemeData
│   └── utils/
│       ├── formatters.dart
│       ├── validators.dart
│       └── extensions.dart
├── app.dart                         # MatchLogApp root widget
└── main.dart                        # Entry point
```

---

## Component Designs

### 1. Design System

#### `colors.dart`

```dart
/// Single source of truth for all MatchLog colors.
/// FPL-inspired dark palette — never hardcode hex values in widgets.
/// 
/// User story: As a developer, I want named color constants so every
/// widget uses the correct palette without magic hex strings.
class MatchLogColors {
  MatchLogColors._();

  // Backgrounds
  static const Color background     = Color(0xFF0E0B16); // Deep dark purple-black
  static const Color surface        = Color(0xFF1A1625); // Card/surface background
  static const Color surfaceElevated = Color(0xFF241F31); // Modals, elevated cards
  static const Color surfaceBorder  = Color(0xFF2D2640); // Subtle borders

  // Primary — FPL Razzmatazz magenta
  static const Color primary        = Color(0xFFE90052);
  static const Color primaryLight   = Color(0xFFFF3378);
  static const Color primaryDark    = Color(0xFFB80042);
  static const Color primarySurface = Color(0xFF2A0F1D); // Tint on dark bg

  // Secondary — Electric violet
  static const Color secondary        = Color(0xFF963CFF);
  static const Color secondaryLight   = Color(0xFFB06FFF);
  static const Color secondaryDark    = Color(0xFF7B2DD4);
  static const Color secondarySurface = Color(0xFF1A0F2A);

  // Semantic
  static const Color success        = Color(0xFF00DC82); // Bet won, correct prediction
  static const Color successSurface = Color(0xFF0A1F16);
  static const Color error          = Color(0xFFFF4D6A); // Bet lost, incorrect
  static const Color errorSurface   = Color(0xFF1F0A10);
  static const Color warning        = Color(0xFFFFB800); // Pending bets
  static const Color warningSurface = Color(0xFF1F1A0A);

  // Text
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0A8C0);
  static const Color textTertiary  = Color(0xFF6B6080);
  static const Color textDisabled  = Color(0xFF4A4058);

  // Sport accents — used when sport context is active
  static const Color footballAccent   = Color(0xFF00DC82); // Green — the pitch
  static const Color basketballAccent = Color(0xFFFF8A00); // Orange
  static const Color f1Accent         = Color(0xFFE10600); // F1 red
  static const Color mmaAccent        = Color(0xFFFF6B35); // UFC orange-red
  static const Color cricketAccent    = Color(0xFF00B4D8); // Blue
  static const Color tennisAccent     = Color(0xFFCCFF00); // Yellow-green
}
```

#### `typography.dart`

Uses `google_fonts` package. Two typefaces:
- **Inter** — all UI text (headlines, body, labels, stats)
- **JetBrains Mono** — odds display only (monospaced so `2.10` and `1.85` align in lists)

```dart
class MatchLogTypography {
  MatchLogTypography._();

  static TextStyle get headlineXL => GoogleFonts.inter(
    fontSize: 32, fontWeight: FontWeight.w800,
    color: MatchLogColors.textPrimary, letterSpacing: -0.5,
  );
  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 24, fontWeight: FontWeight.w700,
    color: MatchLogColors.textPrimary, letterSpacing: -0.3,
  );
  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: MatchLogColors.textPrimary,
  );
  static TextStyle get headlineSmall => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: MatchLogColors.textPrimary,
  );
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: MatchLogColors.textSecondary, height: 1.5,
  );
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: MatchLogColors.textSecondary, height: 1.5,
  );
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: MatchLogColors.textTertiary,
  );
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: MatchLogColors.textPrimary, letterSpacing: 0.5,
  );
  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: MatchLogColors.textTertiary, letterSpacing: 0.5,
  );
  static TextStyle get statNumber => GoogleFonts.inter(
    fontSize: 36, fontWeight: FontWeight.w900,
    color: MatchLogColors.textPrimary,
  );
  // Odds — monospaced so values align in bet lists
  static TextStyle get oddsDisplay => GoogleFonts.jetBrainsMono(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: MatchLogColors.primary,
  );
}
```

#### `spacing.dart`

4pt grid. All widgets use these constants — no raw doubles.

```dart
class MatchLogSpacing {
  MatchLogSpacing._();

  static const double xs    = 4.0;
  static const double sm    = 8.0;
  static const double md    = 12.0;
  static const double lg    = 16.0;
  static const double xl    = 24.0;
  static const double xxl   = 32.0;
  static const double xxxl  = 48.0;

  static const EdgeInsets screenPadding     = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets cardPadding       = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(12.0);

  static const double radiusSm   = 8.0;
  static const double radiusMd   = 12.0;
  static const double radiusLg   = 16.0;
  static const double radiusXl   = 24.0;
  static const double radiusFull = 100.0; // Pill shape
}
```

#### `app_theme.dart`

Assembles `ThemeData` from the three files above. Single place to change the app's visual identity.

Key decisions:
- `CardTheme` uses `surfaceBorder` side — cards have a subtle border, not a shadow
- `ElevatedButton` has zero elevation — flat, modern look
- `InputDecoration` uses `surfaceElevated` fill — inputs feel inset on the dark background

---

### 2. Environment Configuration

#### `app_config.dart`

```dart
/// Reads --dart-define build flags. Two environments: staging and prod.
/// 
/// Usage:
///   flutter run --dart-define=ENV=staging --dart-define=FOOTBALL_API_KEY=xxx
///   flutter build appbundle --dart-define=ENV=prod --dart-define=FOOTBALL_API_KEY=xxx
enum Environment { staging, prod }

class AppConfig {
  final Environment environment;
  final String footballApiKey;
  final String footballApiBaseUrl;
  final String geminiApiKey;

  static late AppConfig instance;

  AppConfig._({...});

  factory AppConfig.fromEnvironment() {
    const env = String.fromEnvironment('ENV', defaultValue: 'staging');
    return AppConfig._(
      environment: env == 'prod' ? Environment.prod : Environment.staging,
      footballApiKey: const String.fromEnvironment('FOOTBALL_API_KEY'),
      footballApiBaseUrl: const String.fromEnvironment(
        'FOOTBALL_API_URL',
        defaultValue: 'https://www.thesportsdb.com/api/v1/json',
      ),
      geminiApiKey: const String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
    );
  }

  bool get isStaging => environment == Environment.staging;
  bool get isProd => environment == Environment.prod;
}
```

#### `backend_config.dart`

```dart
/// Controls which data source implementations are active.
/// firebase = Phase 1-3. spring = Phase 4+.
/// Swapped via Riverpod provider — presentation layer never changes.
enum BackendType { firebase, spring }

class BackendConfig {
  final BackendType type;
  const BackendConfig({this.type = BackendType.firebase});
}
```

---

### 3. Routing

#### `routes.dart`

```dart
/// Named route constants. Import this class instead of typing route
/// strings inline — prevents typos and makes refactoring safe.
abstract class Routes {
  static const home        = '/';
  static const diary       = '/diary';
  static const logMatch    = '/diary/log';
  static const matchDetail = '/diary/:id';
  static const betting     = '/betting';
  static const logBet      = '/betting/log';
  static const stats       = '/stats';
  static const profile     = '/profile';
  static const settings    = '/settings';
}
```

#### `app_router.dart`

```dart
/// GoRouter instance. All Phase 1 routes defined here.
/// Unknown routes redirect to home.
/// debugLogDiagnostics enabled in staging only.
class AppRouter {
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: AppConfig.instance.isStaging,
    initialLocation: Routes.diary,
    errorBuilder: (context, state) => const DiaryPlaceholderScreen(),
    routes: [
      GoRoute(path: Routes.home, redirect: (_, __) => Routes.diary),
      GoRoute(path: Routes.diary, builder: ...),
      GoRoute(path: Routes.logMatch, builder: ...),
      GoRoute(path: Routes.matchDetail, builder: ...),
      GoRoute(path: Routes.betting, builder: ...),
      GoRoute(path: Routes.logBet, builder: ...),
      GoRoute(path: Routes.stats, builder: ...),
      GoRoute(path: Routes.profile, builder: ...),
      GoRoute(path: Routes.settings, builder: ...),
    ],
  );
}
```

Phase 1 routes point to placeholder screens. Feature screens are wired in subsequent phases.

---

### 4. Dependency Injection

#### `providers.dart`

```dart
/// Core app-wide Riverpod providers.
/// Feature providers live in their own feature/presentation/providers/ files.

// Singleton database instance
@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) => AppDatabase();

// Network connectivity stream
@Riverpod(keepAlive: true)
Stream<ConnectivityResult> connectivity(ConnectivityRef ref) =>
    Connectivity().onConnectivityChanged;

// Active backend config (firebase in Phase 1-3)
@Riverpod(keepAlive: true)
BackendConfig backendConfig(BackendConfigRef ref) =>
    const BackendConfig(type: BackendType.firebase);
```

#### `service_locator.dart`

```dart
/// Ordered initialization before runApp.
/// Order matters: Flutter bindings → Firebase → AppConfig → runApp.
class ServiceLocator {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppConfig.instance = AppConfig.fromEnvironment();
  }
}
```

---

### 5. Drift Database

#### Domain Enums (defined in `type_converters.dart`)

All enums are stored as integers in SQLite via Drift's `intEnum` converter.

| Enum | Values |
|------|--------|
| `Sport` | football, basketball, formula1, mma, cricket, tennis |
| `WatchType` | stadium, tv, streaming, radio |
| `BetType` | win, draw, btts, overUnder, correctScore, accumulator, moneyline, prop |
| `BetVisibility` | public, friends, private_ |
| `UserTier` | free, pro, crew |
| `GroupPrivacy` | open, inviteOnly |
| `GroupRole` | admin, member |
| `PredictionConfidence` | high, medium, low |
| `VerificationStatus` | pending, verified, rejected, flagged |
| `TruthTier` | unverified, bronze, silver, gold, diamond |

JSON columns use `JsonListConverter` and `JsonMapConverter` — both serialize to TEXT.

#### Table Schema

**`MatchEntries`**
| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v4 |
| userId | TEXT | Firebase UID |
| sport | INT | intEnum\<Sport\> |
| fixtureId | TEXT | TheSportsDB event ID |
| homeTeam | TEXT | |
| awayTeam | TEXT? | Null for individual sports (F1, MMA) |
| score | TEXT | "2-1", "110-98", "P1: VER" |
| league | TEXT | |
| watchType | INT | intEnum\<WatchType\> |
| rating | INT | CHECK 1–5 |
| review | TEXT? | |
| photos | TEXT | JsonList of Storage URLs |
| venue | TEXT? | Stadium name |
| sportMetadata | TEXT | JsonMap for sport-specific fields |
| geoVerified | BOOL | Default false |
| createdAt | DATETIME | |
| updatedAt | DATETIME? | |
| synced | BOOL | Default false — offline-first flag |

**`BetEntries`**
| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | |
| userId | TEXT | |
| sport | INT | intEnum\<Sport\> |
| fixtureId | TEXT | |
| matchDescription | TEXT | "Arsenal vs Chelsea" |
| betType | INT | intEnum\<BetType\> |
| prediction | TEXT | "Arsenal to Win" |
| odds | REAL | |
| stake | REAL | |
| currency | TEXT | Default 'NGN' |
| bookmaker | TEXT | |
| settled | BOOL | Default false |
| won | BOOL? | Null until settled |
| payout | REAL? | |
| settledAt | DATETIME? | |
| visibility | INT | intEnum\<BetVisibility\> |
| createdAt | DATETIME | |
| synced | BOOL | Default false |

**`BookieGroups`**
| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | |
| name | TEXT | |
| adminId | TEXT | |
| privacy | INT | intEnum\<GroupPrivacy\> |
| inviteCode | TEXT UNIQUE | 6-char alphanumeric |
| leagueFocus | TEXT? | Nullable JsonList |
| sportFocus | INT? | Nullable intEnum\<Sport\> |
| memberCount | INT | Default 0, denormalized |
| createdAt | DATETIME | |
| synced | BOOL | Default false |

**`GroupMembers`** — composite PK (groupId, userId)

**`Predictions`** — includes `kickoffAt` for hard submission deadline enforcement

**`Follows`** — composite PK (followerId, followingId)

**`UserProfiles`** — PK userId, cached locally for offline profile display

**`SyncQueue`** — auto-increment id, stores pending create/update/delete ops

**`FixtureCache`** — PK fixtureId, includes `expiresAt` for TTL-based invalidation

**`ScannedBetSlips`** — OCR scan results, Phase 2 feature, schema defined now

**`TruthScores`** — PK userId, computed verification scores, Phase 3 feature

#### DAO Design

Each DAO is annotated with `@DriftAccessor` and provides:
- **Insert** — takes a `Companion` object
- **Update** — takes a `Companion` with the id set
- **Watch** — returns `Stream<List<T>>` for reactive UI
- **Get** — returns `Future<List<T>>` for one-shot reads
- **Unsynced** — returns rows where `synced = false` for the sync worker

```dart
// Pattern used by all DAOs
@DriftAccessor(tables: [MatchEntries])
class MatchDao extends DatabaseAccessor<AppDatabase> with _$MatchDaoMixin {
  MatchDao(super.db);

  Future<void> insertMatch(MatchEntriesCompanion entry) =>
      into(matchEntries).insert(entry);

  Stream<List<MatchEntry>> watchMatchesByUser(String userId) =>
      (select(matchEntries)
        ..where((t) => t.userId.equals(userId))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Future<List<MatchEntry>> getUnsyncedMatches() =>
      (select(matchEntries)..where((t) => t.synced.equals(false))).get();
}
```

#### SyncQueue Access Pattern

```
Write operation triggered
        │
        ▼
  Insert to Drift (always)
        │
   Online? ──Yes──▶ POST to Firebase ──Success──▶ mark synced=true
        │                              │
       No                            Fail
        │                              │
        ▼                              ▼
  SyncQueue.enqueue()          SyncQueue.enqueue()
        │
  On connectivity restored:
        │
  SyncQueue.getPending()
        │
  For each op: executeRemote()
        │
  Success: markCompleted()
  Fail (retry < 3): incrementRetry()
  Fail (retry = 3): markFailed()
```

---

### 6. Utilities

#### `formatters.dart`

```dart
class CurrencyFormatter {
  static String format(double amount, String currency) {
    // Uses intl NumberFormat with locale-aware symbols
    // NGN → ₦1,000.00 | USD → $1,000.00 | Unknown → XYZ 1,000.00
  }
}

class OddsFormatter {
  static String format(double odds) => odds.toStringAsFixed(2);
}

class DateFormatter {
  static String formatRelative(DateTime date) {
    // Today / Yesterday / Apr 15, 2025
  }
  static String formatFull(DateTime date) {
    // Apr 15, 2025
  }
}
```

#### `validators.dart`

All validators follow the Flutter `FormField` contract — return `String?` (null = valid).

```dart
class Validators {
  static String? required(String? value) { ... }
  static String? email(String? value) { ... }
  static String? odds(String? value) { ... }  // Must parse as double > 1.0
  static String? stake(String? value) { ... } // Must parse as positive double
  static String? rating(int? value) { ... }   // Must be 1–5 inclusive
}
```

---

### 7. Entry Point

#### `app.dart`

```dart
/// Root widget. Wires GoRouter + AppTheme.dark.
/// Wrapped in ProviderScope in main.dart.
class MatchLogApp extends StatelessWidget {
  const MatchLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MatchLog',
      theme: AppTheme.dark,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

#### `main.dart`

```dart
/// Entry point. Initialization order is critical:
/// 1. Flutter bindings
/// 2. Firebase
/// 3. AppConfig
/// 4. runApp
void main() async {
  await ServiceLocator.initialize();
  runApp(const ProviderScope(child: MatchLogApp()));
}
```

---

## Testing Strategy

### Unit Tests

| Test file | What it covers |
|-----------|---------------|
| `test/core/utils/formatters_test.dart` | CurrencyFormatter (NGN, USD, unknown), OddsFormatter (2 d.p.), DateFormatter (today/yesterday/full) |
| `test/core/utils/validators_test.dart` | required, email, odds (>1.0), stake (positive), rating (1–5) |

### Drift DAO Tests (in-memory)

```dart
// All DAO tests use NativeDatabase.memory() — no file system, no cleanup needed
final db = AppDatabase(NativeDatabase.memory());
```

| Test file | What it covers |
|-----------|---------------|
| `test/core/database/match_dao_test.dart` | insert → get, unsynced filter, watch stream |
| `test/core/database/bet_dao_test.dart` | insert → unsettled filter, unsynced filter |
| `test/core/database/group_dao_test.dart` | insert group → getById, insert member → getMembers |
| `test/core/database/prediction_dao_test.dart` | insert → watchForGroup stream |
| `test/core/database/sync_queue_test.dart` | enqueue → getPending, markCompleted, incrementRetry → failed |

### Property-Based Tests

The SyncQueue payload round-trip is a correctness property:

```
∀ valid JSON maps M:
  jsonDecode(jsonEncode(M)) == M
```

This is tested with multiple payload shapes to catch edge cases (nested maps, arrays, null values, unicode strings).

---

## Correctness Properties

| Property | Description |
|----------|-------------|
| **Sync idempotency** | Enqueuing the same operation twice and replaying once produces the same remote state as enqueuing once |
| **Cache TTL** | `getCachedFixture` never returns a row where `expiresAt < DateTime.now()` |
| **Rating bounds** | `MatchEntries.rating` is always in [1, 5] — enforced at DB level via CHECK constraint |
| **Odds validity** | `BetEntries.odds` is always > 1.0 — enforced at validator level before insert |
| **JSON round-trip** | All JsonList and JsonMap columns survive encode → decode without data loss |
