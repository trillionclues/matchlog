# MatchLog — Development Guide

> Local setup, project structure, coding conventions, and day-to-day development workflow.

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| **Flutter SDK** | 3.24+ (stable) | Framework |
| **Dart SDK** | 3.5+ | Language (bundled with Flutter) |
| **Android Studio** or **VS Code** | Latest | IDE |
| **Xcode** | 15+ | iOS builds (macOS only) |
| **Firebase CLI** | Latest | Firebase project management |
| **FlutterFire CLI** | Latest | Firebase Flutter configuration |
| **Node.js** | 18+ | Firebase Cloud Functions |
| **CocoaPods** | Latest | iOS dependencies |
| **Java JDK** | 17+ | Android builds + Phase 4 Spring Boot |

---

## Project Setup

### 1. Create Flutter Project

```bash
flutter create matchlog --org com.matchlog --platforms android,ios
cd matchlog
```

### 2. Configure Firebase

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Create Firebase project
firebase projects:create matchlog-app

# Configure Flutter app
flutterfire configure --project=matchlog-app
```

### 3. Install Core Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.2.0

  # Network
  dio: ^5.4.3+1
  connectivity_plus: ^6.0.3

  # Local Database (Offline-First)
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.20

  # Firebase
  firebase_core: ^2.31.0
  firebase_auth: ^4.19.5
  cloud_firestore: ^4.17.3
  firebase_storage: ^11.7.5
  firebase_messaging: ^14.9.1

  # UI
  flutter_animate: ^4.5.0
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  fl_chart: ^0.68.0           # Charts
  table_calendar: ^3.1.1       # Calendar view

  # Media
  image_picker: ^1.1.1
  image_cropper: ^7.0.5
  share_plus: ^9.0.0

  # Notifications
  flutter_local_notifications: ^17.2.1+2

  # Location
  geolocator: ^12.0.0
  geocoding: ^3.0.0

  # Deep Linking
  app_links: ^6.1.1

  # Storage
  flutter_secure_storage: ^9.2.2

  # Utils
  intl: ^0.19.0                # Date/number formatting
  uuid: ^4.4.0
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  drift_dev: ^2.18.0
  mockito: ^5.4.4
  mocktail: ^1.0.3
```

### 4. Run Code Generation

```bash
# Generate Drift database, Freezed models, Riverpod providers
dart run build_runner build --delete-conflicting-outputs

# Watch mode during development
dart run build_runner watch --delete-conflicting-outputs
```

---

## Project Structure Conventions

### File Naming

| Item | Convention | Example |
|------|-----------|---------|
| Files | `snake_case.dart` | `match_entry.dart` |
| Classes | `PascalCase` | `MatchEntry` |
| Variables/Functions | `camelCase` | `calculateRoi()` |
| Constants | `camelCase` or `SCREAMING_SNAKE` | `maxFreeGroupSize` |
| Providers | `camelCaseProvider` | `diaryEntriesProvider` |
| Screens | `*_screen.dart` | `diary_screen.dart` |
| Widgets | `*_widget.dart` or descriptive | `match_card.dart` |

### Feature Module Convention

Every feature follows this structure:

```
features/{feature_name}/
├── data/
│   ├── {feature}_repository_impl.dart   # Implements domain interface
│   ├── {feature}_local_source.dart      # Drift DAO
│   ├── {feature}_firebase_source.dart   # Firestore operations
│   └── {feature}_spring_source.dart     # REST API (Phase 4, empty initially)
├── domain/
│   ├── entities/                         # Pure Dart data classes (Freezed)
│   ├── repositories/                     # Abstract interfaces
│   └── usecases/                         # Single-purpose business logic
└── presentation/
    ├── screens/                          # Full-page widgets
    ├── widgets/                          # Reusable UI components
    └── providers/                        # Riverpod providers for this feature
```

### Import Rules

```dart
// ✅ CORRECT: Feature presentation imports domain
import 'package:matchlog/features/diary/domain/entities/match_entry.dart';

// ❌ WRONG: Feature presentation imports data directly
import 'package:matchlog/features/diary/data/diary_firebase_source.dart';

// ❌ WRONG: One feature imports another feature's internals
import 'package:matchlog/features/betting/data/betting_repository_impl.dart';

// ✅ CORRECT: Cross-feature dependency via shared provider
final combinedStats = ref.watch(diaryStatsProvider);
```

---

## Entity Definitions (Freezed)

```dart
// features/diary/domain/entities/match_entry.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:matchlog/features/match_search/domain/entities/sport.dart';

part 'match_entry.freezed.dart';
part 'match_entry.g.dart';

@freezed
class MatchEntry with _$MatchEntry {
  const factory MatchEntry({
    required String id,
    required String userId,
    required Sport sport,
    required String fixtureId,
    required String homeTeam,
    String? awayTeam,
    required String score,
    required String league,
    required WatchType watchType,
    required int rating,
    String? review,
    @Default([]) List<String> photos,
    String? venue,
    @Default({}) Map<String, dynamic> sportMetadata,
    @Default(false) bool geoVerified,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _MatchEntry;

  factory MatchEntry.fromJson(Map<String, dynamic> json) =>
      _$MatchEntryFromJson(json);
}
```

---

## Repository Pattern

```dart
// Domain: Abstract interface (pure Dart)
abstract class DiaryRepository {
  Future<List<MatchEntry>> getEntries({
    required String userId,
    Sport? sport,
    int? limit,
    DateTime? after,
  });
  Future<MatchEntry> logMatch(MatchEntry entry);
  Future<void> deleteEntry(String entryId);
  Stream<List<MatchEntry>> watchEntries(String userId);
}

// Data: Implementation (picks local vs remote)
class DiaryRepositoryImpl implements DiaryRepository {
  final DiaryLocalSource _local;
  final DiaryRemoteSource _remote;
  final ConnectivityService _connectivity;
  final SyncQueue _syncQueue;

  DiaryRepositoryImpl(this._local, this._remote, this._connectivity, this._syncQueue);

  @override
  Future<MatchEntry> logMatch(MatchEntry entry) async {
    // 1. Always write locally first
    await _local.insert(entry);

    // 2. Sync to remote if online, else queue
    if (await _connectivity.isOnline) {
      await _remote.create(entry);
    } else {
      await _syncQueue.enqueue(SyncOperation.create('match_entries', entry.id, entry.toJson()));
    }

    return entry;
  }

  @override
  Future<List<MatchEntry>> getEntries({
    required String userId,
    Sport? sport,
    int? limit,
    DateTime? after,
  }) async {
    // Read from local first (instant)
    final localEntries = await _local.getEntries(userId: userId, sport: sport, limit: limit);

    // Background refresh from remote
    if (await _connectivity.isOnline) {
      unawaited(_refreshFromRemote(userId));
    }

    return localEntries;
  }
}
```

---

## Running the App

```bash
# Development (debug mode)
flutter run

# Specific device
flutter run -d <device_id>
flutter devices    # List available devices

# Release builds
flutter build apk --release        # Android APK
flutter build appbundle --release   # Android App Bundle (for Play Store)
flutter build ios --release         # iOS (requires Xcode)

# Run tests
flutter test
flutter test --coverage

# Analyze code
flutter analyze
dart fix --apply
```

---

## Environment Configuration

```dart
// core/config/app_config.dart
enum Environment { dev, staging, prod }

class AppConfig {
  final Environment environment;
  final String footballApiKey;
  final String footballApiBaseUrl;
  final String? geminiApiKey;

  static late AppConfig instance;

  AppConfig._({
    required this.environment,
    required this.footballApiKey,
    required this.footballApiBaseUrl,
    this.geminiApiKey,
  });

  factory AppConfig.fromEnvironment() {
    // Read from --dart-define flags
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    return AppConfig._(
      environment: Environment.values.byName(env),
      footballApiKey: const String.fromEnvironment('FOOTBALL_API_KEY'),
      footballApiBaseUrl: const String.fromEnvironment(
        'FOOTBALL_API_URL',
        defaultValue: 'https://www.thesportsdb.com/api/v1/json',
      ),
      geminiApiKey: const String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
    );
  }
}
```

```bash
# Run with environment variables
flutter run --dart-define=ENV=dev \
            --dart-define=FOOTBALL_API_KEY=your_key_here \
            --dart-define=GEMINI_API_KEY=your_gemini_key
```

---

## Common Development Tasks

### Adding a New Feature

1. Create feature directory: `lib/features/{name}/`
2. Define entities in `domain/entities/` (Freezed classes)
3. Define repository interface in `domain/repositories/`
4. Implement data sources in `data/`
5. Create providers in `presentation/providers/`
6. Build screens and widgets in `presentation/`
7. Register routes in `core/router/app_router.dart`
8. Run `dart run build_runner build`

### Adding a New Sport (Phase 4+)

1. Add value to `Sport` enum
2. Implement `FixtureDataSource` for the sport's API
3. Implement `SportPlugin` with bet types and metadata fields
4. Register in the sport provider registry
5. No database migration needed — `sportMetadata` handles new fields

### Debugging Drift Database

```dart
// Inspect local database during development
import 'package:drift_dev/api/migrations.dart';

// Enable query logging
final db = AppDatabase(logStatements: true);
```

---

## Code Quality

### Linting Rules

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - avoid_print                   # Use logger instead
    - prefer_single_quotes
    - require_trailing_commas
    - sort_constructors_first
    - unawaited_futures             # Important for offline-first
    - prefer_final_locals
```

### Pre-commit Checks

```bash
# Run before committing
flutter analyze && flutter test && dart format lib/ test/
```
