# Requirements Document

## Introduction

The Diary feature is the core MatchLog experience: users log matches they watched, browse a personal diary feed, open full match details, and review their personal stats. It is the "diary first" foundation described in [docs/PROJECT.md](../../../docs/PROJECT.md), and it must feel useful even before any social or AI features ship.

This feature builds on the completed Phase 1 foundation:

1. `AppDatabase`, `MatchEntries`, `MatchDao`, and `SyncQueue` are the local offline-first persistence layer
2. Riverpod providers are the dependency injection and state propagation mechanism
3. GoRouter route constants and guards are already defined in core routing
4. The design system, shared widgets, formatters, and validators from foundation must be reused instead of duplicated

The diary remains offline-first. All writes land in Drift first, sync to Firebase when possible, and never depend on network availability to succeed on-device. `geoVerified` exists on `MatchEntry` but stadium verification itself belongs to the later `phase1-5-extras` spec; diary logging must default it to `false` until that feature lands.

---

## Glossary

- **MatchEntry**: The domain entity representing one watched match log.
- **UserStats**: The computed summary model for a user's diary and betting performance.
- **DiaryRepository**: The abstract domain contract for diary reads, writes, deletes, and stats access.
- **DiaryRepositoryImpl**: The data-layer implementation that composes Drift, Firebase, and the sync queue.
- **DiaryLocalSource**: The Drift-backed source wrapping `MatchDao` and any local query helpers.
- **DiaryFirebaseSource**: The Firebase-backed source for Firestore `match_entries` documents and Firebase Storage photo uploads.
- **MatchDao**: The existing Phase 1 DAO for `MatchEntries` reads and writes inside `AppDatabase`.
- **SyncQueue**: The existing local queue table used to replay offline create and delete operations when connectivity returns.
- **DiaryScreen**: The main diary feed screen shown on the first bottom-nav tab.
- **LogMatchScreen**: The form screen used to create a new `MatchEntry`.
- **MatchDetailScreen**: The detail view for one diary entry, including photos and full review text.
- **StatsDashboard**: The personal stats screen summarizing diary activity and betting performance.
- **WatchType**: The existing enum for `stadium`, `tv`, `streaming`, and `radio`.

---

## Requirements

### Requirement 1: Domain Layer Contracts

**User Story:** As a developer, I want pure domain entities, failures, repository interfaces, and use cases for the diary feature, so that the feature remains testable, backend-agnostic, and compliant with Clean Architecture.

#### Acceptance Criteria

1. THE `MatchEntry` entity SHALL be a Freezed value object with fields matching [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md): `id`, `userId`, `sport`, `fixtureId`, `homeTeam`, `awayTeam`, `score`, `league`, `watchType`, `rating`, `review`, `photos`, `venue`, `sportMetadata`, `geoVerified`, `createdAt`, and `updatedAt`.
2. THE `MatchEntry` entity SHALL contain zero imports from Flutter framework packages, Firebase packages, or Drift packages.
3. THE `UserStats` entity SHALL be a pure Dart model containing the fields defined in [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md): `totalMatchesWatched`, `matchesThisMonth`, `matchesByLeague`, `matchesByTeam`, `matchesByWatchType`, `averageRating`, `stadiumVisits`, `currentStreak`, `longestStreak`, `totalBets`, `betsWon`, `betsLost`, `betsPending`, `winRate`, `totalStaked`, `totalPayout`, `roi`, `roiByLeague`, `roiByBetType`, `roiByBookmaker`, `mostProfitableLeague`, `mostProfitableBetType`, and `leastProfitableBookmaker`.
4. THE diary domain SHALL define a feature-scoped failure type that presentation code can render without inspecting Firebase or Drift exception classes directly.
5. THE `DiaryRepository` interface SHALL declare `logMatch`, `getEntries`, `watchEntries`, `getEntryById`, `deleteEntry`, and `calculateStats` operations.
6. THE `LogMatch`, `GetDiaryEntries`, `DeleteEntry`, and `CalculateStats` use case classes SHALL each accept the relevant repository contract via constructor injection and expose a single `call()` method.
7. FOR ALL valid `MatchEntry` instances, serializing to and deserializing from JSON SHALL produce an equivalent entity.

---

### Requirement 2: Match Logging Form

**User Story:** As a user, I want to log a watched match with context such as rating, review, venue, and photos, so that my diary feels like a personal journal rather than a bare result list.

#### Acceptance Criteria

1. THE `LogMatchScreen` SHALL allow the user to start from a selected fixture context and complete the fields required to create a `MatchEntry`.
2. THE `LogMatchScreen` SHALL collect `watchType` and `rating` as required fields before submission.
3. THE `LogMatchScreen` SHALL allow optional `review`, optional `venue`, optional `sportMetadata`, and optional attached photos.
4. THE `LogMatchScreen` SHALL reuse the existing Phase 1 design tokens and shared validators rather than introducing raw spacing, colors, or duplicate validation helpers.
5. WHEN the user submits a valid log, THE feature SHALL create a `MatchEntry` with a generated `id`, the authenticated user's `userId`, `createdAt`, and `geoVerified = false` unless a later feature explicitly upgrades it.
6. IF the user attempts to submit without a required match context, watch type, or valid 1-5 rating, THEN THE screen SHALL show field-level validation errors before any repository call is made.
7. WHILE a log-match submission is in progress, THE `LogMatchScreen` SHALL disable repeat submission and display a loading state.

---

### Requirement 3: Offline-First Persistence

**User Story:** As a user with unreliable connectivity, I want logging a match to succeed immediately on my device, so that the app remains useful offline.

#### Acceptance Criteria

1. WHEN `logMatch` is called, THE repository SHALL write the new entry to the local `MatchEntries` table via the existing `MatchDao` before any remote operation is attempted.
2. WHEN the device is online and remote sync succeeds, THE repository SHALL mark the local row as synced.
3. WHEN the device is offline, or when the remote create fails after the local write succeeds, THE repository SHALL enqueue a pending `create` operation in `SyncQueue` with `collection = 'match_entries'`.
4. WHEN connectivity returns, THE queued `match_entries` create operations SHALL be replayed in creation order through the existing sync infrastructure.
5. THE local write path SHALL never depend on Firestore or Firebase Storage availability to report success on-device.
6. WHEN a previously queued match entry syncs successfully, THE corresponding local row SHALL be updated so future reads reflect the synced state.

---

### Requirement 4: Firebase Sync and Photo Uploads

**User Story:** As a user, I want my diary to sync across devices and preserve attached photos, so that my entries survive device changes and reinstalls.

#### Acceptance Criteria

1. THE remote source SHALL persist diary documents to the Firestore `match_entries/{entryId}` collection structure defined in [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md).
2. THE Firestore payload SHALL include `userId`, `sport`, `fixtureId`, `homeTeam`, `awayTeam`, `score`, `league`, `watchType`, `rating`, `review`, `photos`, `venue`, `sportMetadata`, `geoVerified`, `createdAt`, and `updatedAt`.
3. WHEN a diary entry includes photos, THE remote source SHALL upload them under `users/{userId}/match_photos/{entryId}/` in Firebase Storage before considering the remote sync complete.
4. WHEN photo upload succeeds, THE Firestore document SHALL store Firebase Storage URLs, and THE local row SHALL be updated to the same photo URL list after sync.
5. IF remote photo upload or Firestore write fails, THEN THE repository SHALL leave the local entry available and queue the remaining remote work for retry rather than deleting or corrupting the local entry.
6. THE diary feature SHALL not set `geoVerified = true` on its own; that flag remains reserved for the stadium check-in feature in Phase 1.5.

---

### Requirement 5: Diary Feed

**User Story:** As a user, I want a fast, scannable feed of the matches I have logged, so that I can revisit recent matches and build a habit around the app.

#### Acceptance Criteria

1. THE `DiaryScreen` SHALL read from local Drift-backed data first and render without waiting for a remote round trip.
2. THE diary feed SHALL order entries by `createdAt` descending, with the newest entries shown first.
3. THE `DiaryScreen` SHALL render a `MatchCard` per entry showing the stored league, watch context, teams, score, rating, review preview, photo count, and logged date.
4. THE `DiaryScreen` SHALL expose filter chips appropriate for the diary feed rather than forcing users into a long unfiltered list.
5. THE `DiaryScreen` SHALL reuse the shared loading, empty, and error states from the Phase 1 foundation where applicable.
6. WHEN the user taps the floating action button on `DiaryScreen`, THE app SHALL navigate to `LogMatchScreen` using the existing GoRouter route configuration.
7. WHEN the user taps a `MatchCard`, THE app SHALL navigate to the matching `MatchDetailScreen`.
8. WHEN the device is online, THE repository MAY refresh from Firestore in the background, but THE existing local list SHALL remain visible during that refresh.

---

### Requirement 6: Match Detail View

**User Story:** As a user, I want to open a full detail page for a logged match, so that I can read the full review, inspect photos, and manage the entry.

#### Acceptance Criteria

1. THE `MatchDetailScreen` SHALL load a diary entry by `entryId` and render the full stored `MatchEntry`.
2. THE detail view SHALL show the complete review text when present, rather than the truncated preview used in the feed.
3. THE detail view SHALL render any attached photos using the shared photo grid patterns from the Phase 1 foundation.
4. THE detail view SHALL render `watchType`, `venue`, `league`, and `geoVerified` status when those values are present.
5. IF the selected diary entry cannot be found locally, THEN THE screen SHALL render a recoverable missing-entry state instead of crashing.
6. THE detail screen SHALL allow the owner to delete the entry.
7. WHEN the user confirms deletion, THE repository SHALL remove the local row immediately and either delete remotely or queue a `delete` sync operation when offline.

---

### Requirement 7: Personal Stats Dashboard

**User Story:** As a user, I want a stats dashboard summarizing how I watch matches and how my betting is performing, so that I can reflect on my habits over time.

#### Acceptance Criteria

1. THE `StatsDashboard` SHALL be backed by the `UserStats` model defined in [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md).
2. THE diary stats computation SHALL include at minimum: total matches watched, matches this month, matches by league, matches by team, matches by watch type, average rating, stadium visits, current streak, and longest streak.
3. THE dashboard SHALL also expose the betting summary fields already present on `UserStats`, sourcing them through abstract repository contracts so the diary feature remains decoupled from a concrete betting data implementation.
4. WHEN no bets exist, THE betting fields on `UserStats` SHALL resolve to safe zero or empty values instead of throwing or producing `NaN`.
5. WHEN no diary entries exist, THE dashboard SHALL render an empty or onboarding-friendly state rather than failing the screen.
6. THE stats UI SHALL use existing design system typography, spacing, and card patterns from [docs/DESIGN.md](../../../docs/DESIGN.md), including emphasis on key headline metrics.
7. THE diary feature SHALL own the personal stats dashboard shell and diary-derived calculations; the deeper bet-tracker ROI workflows remain part of the separate betting feature spec.

---

### Requirement 8: Routing and Riverpod Integration

**User Story:** As a developer, I want the diary feature wired into the existing provider graph and app router, so that the feature behaves like a first-class part of the app instead of a one-off module.

#### Acceptance Criteria

1. THE diary feature SHALL expose Riverpod providers for the repository, core use cases, feed state, selected feed filter state, and stats state.
2. THE `diaryEntriesProvider` SHALL expose the current user's diary entries as an `AsyncValue<List<MatchEntry>>`.
3. THE `statsProvider` SHALL expose the current user's `UserStats` as an `AsyncValue<UserStats>`.
4. THE diary feature SHALL derive the active `userId` from the authenticated user provider defined by the auth feature rather than passing it manually through widgets.
5. THE feature SHALL integrate with the existing named routes for diary feed, log match, match detail, and stats instead of hardcoding route strings in widgets.
6. THE diary feature SHALL remain compatible with the existing bottom navigation structure where Diary is tab 1.

---

### Requirement 9: Security and Ownership Rules

**User Story:** As the app, I want diary mutations constrained to the authenticated owner, so that one user cannot create, alter, or delete another user's match logs.

#### Acceptance Criteria

1. THE diary feature SHALL only create or delete remote `match_entries` documents for the currently authenticated user.
2. THE diary feature SHALL only upload match photos into the authenticated user's Firebase Storage namespace under `users/{userId}/match_photos/`.
3. THE feature SHALL respect the Firestore security rule constraint that `rating` must be between 1 and 5.
4. THE feature SHALL never trust a widget-provided `userId` over the authenticated session when building remote mutation payloads.
5. THE diary feature SHALL not broaden diary reads beyond authenticated usage patterns defined by the existing Firebase security model.
6. THE feature SHALL not store API keys, tokens, or other secrets inside diary feature code, local payloads, or synced entry documents.

---

### Requirement 10: Testing and Correctness Properties

**User Story:** As a developer, I want strong automated test coverage for the diary feature, so that offline sync, stats calculations, and screen behavior remain stable as the app grows.

#### Acceptance Criteria

1. THE test suite SHALL include unit tests for `LogMatch`, `GetDiaryEntries`, `DeleteEntry`, and `CalculateStats`.
2. THE test suite SHALL include repository tests covering: local-first create, online create plus remote sync, offline create plus queueing, local-first reads, remote refresh merge, and delete behavior.
3. THE test suite SHALL include widget tests for `DiaryScreen`, `LogMatchScreen`, `MatchDetailScreen`, and `StatsDashboard`.
4. THE test suite SHALL include tests for `MatchCard`, `RatingStars`, and `WatchTypeSelector` behaviors that are critical to diary interactions.
5. FOR ALL valid `MatchEntry` instances, JSON serialization followed by deserialization SHALL return an equivalent entity.
6. FOR ALL valid input sets used to compute `UserStats`, THE sum of `matchesByWatchType` values SHALL equal `totalMatchesWatched`.
7. FOR ALL valid input sets used to compute `UserStats`, THE `averageRating` SHALL stay within the inclusive range `[0, 5]`.
8. FOR ALL valid input sets used to compute `UserStats`, THE `currentStreak` SHALL be less than or equal to `longestStreak`.
9. FOR ALL empty-input cases, THE stats calculator SHALL return zero or empty aggregates without division-by-zero failures.
10. FOR ALL identical remote refresh payloads applied more than once, THE local diary cache merge SHALL be idempotent and SHALL not create duplicate entries.
