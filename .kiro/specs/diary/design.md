# Design Document: Diary

## Overview

The diary feature is the primary Phase 1 product loop: log a match, see it appear instantly in the diary feed, reopen it from detail, and build reflection habits through personal stats. The design follows the existing MatchLog constraints:

1. Drift is the primary local store and first read path
2. Firebase is the Phase 1-3 sync target
3. Riverpod is the feature integration layer
4. GoRouter owns navigation
5. The existing design tokens, shared widgets, and formatters remain the visual and interaction baseline

This feature deliberately stops short of stadium GPS verification and calendar heatmaps. `geoVerified` is preserved in the model and UI, but only the later `phase1-5-extras` feature may elevate it to `true`.

---

## Architecture

### Layering

```text
Presentation  ->  Domain  <-  Data
                   ^          ^
                   |          |
                 Core   Drift + Firestore + Storage + SyncQueue
```

- `domain/` stays pure Dart and declares feature entities, failures, repositories, and use cases
- `data/` composes the existing `AppDatabase` / `MatchDao` with Firestore and Firebase Storage
- `presentation/` owns screens, widgets, filters, and Riverpod-facing controllers/providers
- `core/` supplies routing, DI, design tokens, validators, formatters, and the authenticated user context

### File Structure

```text
lib/
├── core/
│   ├── database/
│   │   ├── app_database.dart
│   │   └── daos/
│   │       └── match_dao.dart
│   ├── di/
│   │   └── providers.dart
│   └── router/
│       ├── app_router.dart
│       └── routes.dart
│
├── shared/
│   └── widgets/
│       ├── empty_state.dart
│       ├── error_state.dart
│       ├── loading_shimmer.dart
│       └── photo_grid.dart
│
└── features/
    └── diary/
        ├── data/
        │   ├── diary_repository_impl.dart
        │   ├── diary_local_source.dart
        │   └── diary_firebase_source.dart
        ├── domain/
        │   ├── entities/
        │   │   ├── match_entry.dart
        │   │   └── user_stats.dart
        │   ├── failures/
        │   │   └── diary_failure.dart
        │   ├── repositories/
        │   │   └── diary_repository.dart
        │   └── usecases/
        │       ├── calculate_stats.dart
        │       ├── delete_entry.dart
        │       ├── get_diary_entries.dart
        │       └── log_match.dart
        └── presentation/
            ├── providers/
            │   ├── diary_providers.dart
            │   └── stats_providers.dart
            ├── screens/
            │   ├── diary_screen.dart
            │   ├── log_match_screen.dart
            │   ├── match_detail_screen.dart
            │   └── stats_dashboard.dart
            └── widgets/
                ├── match_card.dart
                ├── rating_stars.dart
                ├── stat_card.dart
                └── watch_type_selector.dart
```

### Enum Reuse

The older architecture sketch mentions a feature-local `watch_type.dart`, but the completed foundation already centralizes `Sport` and `WatchType` in core enum/converter definitions. This feature should reuse those existing enums instead of duplicating them.

---

## Domain Design

### `MatchEntry`

`MatchEntry` is the canonical diary entity and mirrors the documented local and remote schema.

Design notes:

- `photos` remains `List<String>` so the repository can carry either local file paths or remote Storage URLs during the sync lifecycle
- `sportMetadata` stays open-ended to preserve the sport-agnostic architecture from day one
- `geoVerified` exists now for display and storage compatibility, but is not authoritatively set by this feature

### `UserStats`

The diary feature owns the personal stats dashboard model because the screen is entered from the diary flow, but `UserStats` intentionally spans both diary and betting aggregates.

Design notes:

- diary-derived fields are computed entirely within this feature
- betting-derived fields are requested through abstract repository contracts so the diary feature does not depend on a concrete betting data implementation
- zero-safe defaults are part of the domain logic, not patched in the UI

### `DiaryFailure`

The failure union should hide implementation details such as Firebase, Storage, or Drift exception classes. Useful variants include:

- `validation`
- `network`
- `storage`
- `notFound`
- `permission`
- `unknown`

Each variant should expose presentation-safe messaging.

### Repository Contract

The repository API should look roughly like this:

```dart
abstract interface class DiaryRepository {
  Future<Either<DiaryFailure, Unit>> logMatch(MatchEntry entry);
  Future<List<MatchEntry>> getEntries({
    required String userId,
    DiaryFilter filter = DiaryFilter.all,
  });
  Stream<List<MatchEntry>> watchEntries({
    required String userId,
    DiaryFilter filter = DiaryFilter.all,
  });
  Future<MatchEntry?> getEntryById({
    required String userId,
    required String entryId,
  });
  Future<Either<DiaryFailure, Unit>> deleteEntry({
    required String userId,
    required String entryId,
  });
  Future<UserStats> calculateStats({required String userId});
}
```

`DiaryFilter` can stay presentation-facing and small for Phase 1. A simple enum such as `all`, `stadium`, `tv`, `streaming`, `radio` is sufficient for the feed chips defined in the design docs.

---

## Data Layer Design

### `DiaryLocalSource`

`DiaryLocalSource` wraps the existing `MatchDao` and any small supporting Drift queries needed by this feature.

Responsibilities:

- insert a match log into `MatchEntries`
- delete a local entry by `entryId`
- stream and query entries by `userId`, sorted by `createdAt DESC`
- filter entries locally for the diary feed
- look up a single entry for the detail screen
- update synced status and photo URLs after successful remote sync

This source must stay thin. The domain mapping and sync policy belong in the repository.

### `DiaryFirebaseSource`

`DiaryFirebaseSource` owns the remote persistence concerns:

- create and delete `match_entries/{entryId}` documents in Firestore
- fetch the current user's remote entries for cache refresh
- upload match photos to `users/{userId}/match_photos/{entryId}/photo_{n}.jpg`
- return fully remote-ready payloads back to the repository

It should not know about Riverpod or widget state.

### `DiaryRepositoryImpl`

`DiaryRepositoryImpl` composes:

- `DiaryLocalSource`
- `DiaryFirebaseSource`
- `AppDatabase` sync queue access
- connectivity signal from the existing provider graph
- authenticated user context
- a read-only betting repository dependency for `UserStats`

#### Write Path

```text
LogMatchScreen submit
  -> LogMatch use case
  -> DiaryRepositoryImpl.logMatch
  -> insert into MatchEntries locally
  -> if online: upload photos + write Firestore document + mark synced
  -> else: enqueue SyncQueue create operation
```

Key decision:

- the local write is the success boundary for the user-facing action
- remote sync is best-effort and retried through the queue

#### Read Path

```text
DiaryScreen opens
  -> watchEntries(userId)
  -> local Drift stream emits immediately
  -> if online: fetch Firestore entries in background
  -> merge remote snapshot into Drift
  -> Drift stream re-emits updated local cache
```

Merge rules:

- primary key is `entryId`
- identical remote payloads must not create duplicates
- newer remote payloads replace older local data
- background refresh must not blank the visible local list

#### Delete Path

```text
MatchDetailScreen delete
  -> DeleteEntry use case
  -> remove local row immediately
  -> if online: delete Firestore doc and any remote photos
  -> else: enqueue SyncQueue delete operation
```

Deleting locally first keeps the offline-first contract consistent with create.

### Photo Lifecycle

Photos need explicit handling because the local store and remote store use different representations over time.

Rules:

1. newly attached images may exist only as local file paths before sync
2. after a successful upload, the local row is rewritten with remote Storage URLs
3. if upload fails, the original local entry remains intact and a retryable sync operation is queued
4. the feature does not assume every string in `photos` is already a remote URL

---

## Presentation Design

### `DiaryScreen`

The feed is the app's default authenticated destination. It should feel fast and journal-like rather than admin-like.

Layout:

- top app bar with title and optional stats entry point
- horizontal filter chips under the header
- vertically scrolling list of `MatchCard`
- floating action button to log a match
- shared empty/loading/error states as fallbacks

Behavior:

- renders local data immediately
- preserves scroll position while background refresh runs
- uses existing bottom navigation with Diary as tab 1

### `LogMatchScreen`

The log flow follows the documented interaction: search/select -> rate -> review -> submit.

Form sections:

- selected fixture summary card
- `WatchTypeSelector`
- `RatingStars`
- review text area
- optional venue field
- optional photo attachments

Cross-feature contract:

- the screen should be able to accept a future `Fixture` object or equivalent payload from the separate `match-search` feature through GoRouter `extra`
- the diary domain itself stores a snapshot of the selected match context on `MatchEntry`; it should not depend on live API access at submit time

### `MatchCard`

The card should implement the pattern described in [docs/DESIGN.md](../../../docs/DESIGN.md):

- top metadata row for league, venue, and watch type
- teams and score as the visual focus
- star rating row with truncated review preview
- photo count and formatted date footer

The card is intentionally dense but scannable. Reuse `DateFormatter` and the theme typography instead of inline formatting logic.

### `MatchDetailScreen`

The detail view expands the feed card into a full journal entry:

- full teams and score block
- full metadata row
- rating and complete review
- photo grid
- delete action
- optional geo-verified badge

If the entry is missing, show a recoverable state and let the user navigate back.

### `StatsDashboard`

The stats dashboard is a personal reflection screen, not the full betting analytics surface.

Primary content:

- headline cards for total matches, average rating, current streak, and stadium visits
- breakdown cards or sections for league, team, and watch-type distribution
- compact betting summary from `UserStats`

Non-goals for this feature:

- no calendar heatmap yet
- no advanced ROI dashboard workflows yet
- no social comparison or group leaderboard content

---

## Provider Design

Expected Riverpod surface:

- `diaryRepositoryProvider`
- `logMatchProvider`
- `getDiaryEntriesProvider`
- `deleteEntryProvider`
- `calculateStatsProvider`
- `diaryFilterProvider`
- `diaryEntriesProvider`
- `matchEntryDetailProvider(entryId)`
- `statsProvider`
- `logMatchControllerProvider`

Design notes:

- `diaryEntriesProvider` should listen to auth state so it automatically swaps when the signed-in user changes
- `statsProvider` should rebuild when diary or betting data changes
- mutation controllers should expose loading and error state cleanly to screens

---

## Routing Integration

The feature reuses the Phase 1 named routes:

- `Routes.diary`
- `Routes.logMatch`
- `Routes.matchDetail`
- `Routes.stats`

Routing rules:

- authenticated users land on `Routes.diary`
- FAB from the diary feed navigates to `Routes.logMatch`
- card tap navigates to `Routes.matchDetail`
- stats entry point navigates to `Routes.stats`

The auth feature continues to own access control. Diary should not duplicate redirect logic locally.

---

## Security and Data Integrity

Relevant source constraints:

- Firestore `match_entries` writes require authenticated ownership
- `rating` must stay between 1 and 5
- Firebase Storage paths are user-scoped
- the app remains positioned as a sports diary, not a gambling facilitator

Implementation decisions:

- derive the remote `userId` from the authenticated session, not from free-form widget input
- keep remote payload keys aligned exactly with the documented Firestore schema
- never set `geoVerified = true` from diary UI or repository code
- treat remote merge as deterministic and idempotent to avoid duplicate diary history

---

## Testing Strategy

### Unit Tests

- `log_match_test.dart`
- `get_diary_entries_test.dart`
- `delete_entry_test.dart`
- `calculate_stats_test.dart`
- `match_entry_test.dart` for JSON round-trip

### Repository Tests

- online create: local insert + remote create + mark synced
- offline create: local insert + queue sync + no remote call
- background refresh: local-first return + remote merge
- delete: local delete + remote delete or queued delete
- photo upload reconciliation: local paths rewritten to remote URLs after sync

### Widget Tests

- `diary_screen_test.dart`
- `log_match_screen_test.dart`
- `match_detail_screen_test.dart`
- `stats_dashboard_test.dart`
- `widgets/match_card_test.dart`

### Property-Based Correctness

Properties that should be tested with generated inputs where practical:

1. `MatchEntry` JSON round-trip preserves equality
2. `matchesByWatchType.values.sum == totalMatchesWatched`
3. `0 <= averageRating <= 5`
4. `currentStreak <= longestStreak`
5. empty diary and empty betting inputs yield zero-safe `UserStats`
6. repeated application of the same remote payload leaves the local cache unchanged after the first merge
