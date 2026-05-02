# Design Document: Betting

## Overview

The betting feature provides MatchLog's personal bet tracker: log existing bets manually, settle them later, and analyze profitability across betting habits. It follows the core MatchLog constraints:

1. the app is a tracker, not a sportsbook
2. Drift is the first write and first read path
3. Firebase is the Phase 1-3 sync target
4. Riverpod drives state into the widget tree
5. GoRouter owns screen navigation

This feature shares analytics vocabulary with the diary feature through `UserStats`, but it owns the actual bet lifecycle and ROI dashboard.

---

## Architecture

### Layering

```text
Presentation  ->  Domain  <-  Data
                   ^          ^
                   |          |
                 Core    Drift + Firestore + SyncQueue
```

- `domain/` stays pure Dart and declares entities, failures, repositories, and use cases
- `data/` composes the existing `BetDao` with Firestore and sync queue behavior
- `presentation/` owns screens, widgets, filters, and Riverpod-facing controllers/providers
- `core/` supplies auth context, routing, validators, formatters, design tokens, and DI

### File Structure

```text
lib/
├── core/
│   ├── database/
│   │   ├── app_database.dart
│   │   └── daos/
│   │       └── bet_dao.dart
│   ├── di/
│   │   └── providers.dart
│   └── router/
│       ├── app_router.dart
│       └── routes.dart
│
└── features/
    └── betting/
        ├── data/
        │   ├── betting_repository_impl.dart
        │   ├── betting_local_source.dart
        │   └── betting_firebase_source.dart
        ├── domain/
        │   ├── entities/
        │   │   └── bet_entry.dart
        │   ├── failures/
        │   │   └── betting_failure.dart
        │   ├── repositories/
        │   │   └── betting_repository.dart
        │   └── usecases/
        │       ├── calculate_roi.dart
        │       ├── log_bet.dart
        │       └── settle_bet.dart
        └── presentation/
            ├── providers/
            │   └── betting_providers.dart
            ├── screens/
            │   ├── betting_screen.dart
            │   ├── log_bet_screen.dart
            │   └── roi_dashboard.dart
            └── widgets/
                ├── bet_card.dart
                ├── bookmaker_selector.dart
                ├── odds_input.dart
                └── roi_breakdown.dart
```

### Enum Reuse

The feature should reuse the existing core enums and constants from Phase 1:

- `Sport`
- `BetType`
- `BetVisibility`
- shared bookmaker constants in `lib/shared/constants/bookmakers.dart`

Do not create duplicate enum definitions in the feature layer.

---

## Domain Design

### `BetEntry`

`BetEntry` is the canonical betting entity and mirrors the documented schema for local and remote storage.

Important invariants:

- `odds > 1.0` for standard decimal-odds validation
- `stake >= 0`
- unsettled bets keep `won`, `payout`, and `settledAt` null
- settled bets must have internally consistent result fields

### Computed Properties

The entity extension from the data models doc is part of the feature contract:

- `potentialPayout = stake * odds`
- `profitLoss = payout - stake` for wins
- `profitLoss = -stake` for losses
- `isPending = !settled`

These rules should live in the domain layer so both UI and analytics rely on the same logic.

### ROI Aggregate Model

The architecture docs only name `calculate_roi.dart`, while `UserStats` already carries aggregate betting fields. The cleanest Phase 1 approach is:

- keep `UserStats` as the cross-feature aggregate consumed by diary stats
- define a betting-scoped ROI view model or aggregate DTO for the dedicated `RoiDashboard`
- make sure both derive from the same repository calculation path to avoid drift

The ROI aggregate should include:

- total bets
- wins, losses, pending
- win rate
- total staked
- total payout
- ROI
- profitability by league, bet type, and bookmaker
- best and worst dimensions

Because the documented `BetEntry` schema does not include a dedicated `league` field while `UserStats` requires `roiByLeague`, the Phase 1 implementation needs a deterministic fallback. The recommended approach is:

- derive league from selected fixture context when available at log time
- persist whatever league label is available as part of the user-visible bet context mapping path
- bucket unresolved entries under `"Unknown"` so league analytics stay total-preserving instead of silently excluding data

### `BettingFailure`

The failure union should hide infrastructure details. Useful variants include:

- `validation`
- `network`
- `notFound`
- `alreadySettled`
- `permission`
- `unknown`

Each variant should expose presentation-safe copy.

### Repository Contract

The repository API should look roughly like this:

```dart
abstract interface class BettingRepository {
  Future<Either<BettingFailure, Unit>> logBet(BetEntry entry);
  Future<List<BetEntry>> getEntries({
    required String userId,
    BetFeedFilter filter = BetFeedFilter.all,
  });
  Stream<List<BetEntry>> watchEntries({
    required String userId,
    BetFeedFilter filter = BetFeedFilter.all,
  });
  Future<BetEntry?> getEntryById({
    required String userId,
    required String betId,
  });
  Future<Either<BettingFailure, Unit>> settleBet({
    required String userId,
    required String betId,
    required bool won,
    required double payout,
  });
  Future<BettingRoiSummary> calculateRoi({required String userId});
}
```

`BetFeedFilter` can stay small in Phase 1: `all`, `pending`, and `settled`.

---

## Data Layer Design

### `BettingLocalSource`

`BettingLocalSource` wraps the existing `BetDao` and a small number of focused Drift queries.

Responsibilities:

- insert bets into `BetEntries`
- update settlement fields locally
- stream and query entries by `userId`, sorted by `createdAt DESC`
- filter by pending or settled status
- look up a single bet by `betId`
- update synced state after successful remote operations

### `BettingFirebaseSource`

`BettingFirebaseSource` owns the remote persistence concerns:

- create `bet_entries/{betId}` documents
- update settlement state remotely
- fetch the current user's bet history for cache refresh
- delete bets if the owner removes them later

The remote payload should preserve `matchDescription` even though the Firestore outline is abbreviated, because the feed and analytics need a stable user-visible context snapshot across devices.

No Firebase Storage dependency is required in this Phase 1 betting scope.

### `BettingRepositoryImpl`

`BettingRepositoryImpl` composes:

- `BettingLocalSource`
- `BettingFirebaseSource`
- sync queue access from `AppDatabase`
- connectivity state from core providers
- authenticated user context

#### Log Path

```text
LogBetScreen submit
  -> LogBet use case
  -> BettingRepositoryImpl.logBet
  -> insert into BetEntries locally
  -> if online: write Firestore document + mark synced
  -> else: enqueue SyncQueue create operation
```

Key decision:

- the user-facing success boundary is the local insert, not the remote write

#### Settlement Path

```text
User settles pending bet
  -> SettleBet use case
  -> BettingRepositoryImpl.settleBet
  -> update BetEntries locally
  -> if online: update Firestore document + mark synced
  -> else: enqueue SyncQueue update operation
```

Settlement must be idempotent from the repository's perspective. If a bet is already settled, reject duplicate settlement instead of silently overwriting analytics history.

#### Read Path

```text
BettingScreen opens
  -> watchEntries(userId, filter)
  -> local Drift stream emits immediately
  -> if online: fetch Firestore entries in background
  -> merge remote snapshot into Drift
  -> Drift stream re-emits updated local cache
```

Merge rules:

- primary key is `betId`
- identical remote payloads must not create duplicates
- remote settlement data replaces older local unsynced state only when the remote version is authoritative and not stale
- background refresh must not blank the visible local list

---

## Presentation Design

### `BettingScreen`

The feed is the second-tab ledger for the user's bets.

Layout:

- app bar title and optional ROI entry point
- filter controls for `all`, `pending`, and `settled`
- vertically scrolling list of `BetCard`
- floating action button to log a bet

Behavior:

- renders local bets immediately
- preserves visible data while remote refresh occurs
- remains owner-centric in Phase 1

### `LogBetScreen`

The form follows the documented flow: match -> type -> odds -> stake -> bookmaker.

Form sections:

- selected fixture or manually entered match description
- bet type selector
- prediction input
- `OddsInput`
- stake and currency
- `BookmakerSelector`
- visibility selector

Compliance note:

- the screen must feel like manual journaling, not a sportsbook ticket builder
- there should be no CTA language that suggests placing a new wager through MatchLog

### Settlement UX

Settlement can be implemented as either:

- a dedicated screen for pending bets, or
- a modal / bottom sheet from `BetCard` or bet detail

For Phase 1, the important constraint is correctness:

- pending bets are clearly identifiable
- settlement requires an explicit won/lost choice
- payout is captured or normalized consistently
- already settled bets are not accidentally resettled

### `BetCard`

The card should follow the pattern in [docs/DESIGN.md](../../../docs/DESIGN.md):

- main row with prediction and odds
- visible result badge
- bookmaker, stake, and payout line
- date and match context line

Visual state:

- won -> `success` color treatment
- lost -> `error` color treatment
- pending -> `warning` color treatment

Use the shared odds and currency formatters rather than inline formatting logic.

### `RoiDashboard`

The ROI dashboard is the feature's main insight screen.

Primary content:

- headline stat cards for total bets, win rate, ROI, total staked, and total payout
- ROI-over-time chart
- breakdown section for league, bet type, and bookmaker profitability
- best and worst summaries

Non-goals for this feature:

- no AI recommendations yet
- no verified ROI or OCR-derived data yet
- no social comparison yet

---

## Provider Design

Expected Riverpod surface:

- `bettingRepositoryProvider`
- `logBetProvider`
- `settleBetProvider`
- `calculateRoiProvider`
- `betFeedFilterProvider`
- `betEntriesProvider`
- `betEntryDetailProvider(betId)`
- `bettingRoiProvider`
- `logBetControllerProvider`
- `settleBetControllerProvider`

Design notes:

- `betEntriesProvider` should listen to auth state so the feed updates when the signed-in user changes
- `bettingRoiProvider` should rebuild when bet data changes
- mutation controllers should expose loading and failure state cleanly to the UI

---

## Routing Integration

The feature should integrate with:

- `Routes.betting`
- `Routes.logBet`

If the router does not already expose a dedicated ROI route, add one such as `Routes.roiDashboard` rather than overloading unrelated screens.

Routing rules:

- authenticated users access the feed through the Betting bottom-nav tab
- FAB from the betting feed navigates to `Routes.logBet`
- ROI entry point navigates to the ROI dashboard route

Auth guards remain owned by the auth and core routing layers.

---

## Security and Compliance

Relevant source constraints:

- Firestore `bet_entries` writes require authenticated ownership
- reads are visibility-based for non-owners
- the app must remain clearly distinct from a gambling facilitator

Implementation decisions:

- derive `userId` from auth state, never from free-form widget input
- keep visibility semantics intact on local and remote models
- phrase UI copy around "log", "track", and "settle", not "place" or "bet now"
- keep the feature strictly manual even if future APIs provide convenience context

---

## Testing Strategy

### Unit Tests

- `log_bet_test.dart`
- `settle_bet_test.dart`
- `calculate_roi_test.dart`
- `bet_entry_test.dart` for JSON round-trip and computed-property coverage

### Repository Tests

- online create: local insert + remote create + mark synced
- offline create: local insert + queue sync + no remote call
- online settlement: local update + remote update + mark synced
- offline settlement: local update + queued update + no remote call
- background refresh: local-first return + remote merge

### Widget Tests

- `betting_screen_test.dart`
- `log_bet_screen_test.dart`
- `roi_dashboard_test.dart`
- `widgets/bet_card_test.dart`

### Property-Based Correctness

Properties that should be tested with generated inputs where practical:

1. `BetEntry` JSON round-trip preserves equality
2. `potentialPayout == stake * odds`
3. winning `profitLoss == payout - stake`
4. losing `profitLoss == -stake`
5. zero or empty aggregates produce zero-safe ROI metrics
6. repeated application of the same remote payload leaves the local cache unchanged after the first merge
