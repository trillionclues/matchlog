# Requirements Document

## Introduction

The Betting feature adds MatchLog's bet tracker: users manually log bets they already placed elsewhere, settle those bets when results are known, review a bet feed, and inspect ROI analytics across bookmakers, bet types, and leagues. This is a supporting Phase 1 feature, not the app's identity. It must stay consistent with the product principle in [docs/PROJECT.md](../../../docs/PROJECT.md): diary first, betting second.

This feature builds on the completed Phase 1 foundation and the new diary spec:

1. `AppDatabase`, `BetEntries`, `BetDao`, and `SyncQueue` provide local offline-first persistence
2. Riverpod providers carry repository dependencies and UI state
3. GoRouter owns screen navigation
4. Existing theme tokens, formatters, validators, and shared widgets must be reused
5. `UserStats` already includes betting aggregates and must remain compatible with the diary stats dashboard

The feature is strictly a manual tracker for compliance. As required by [docs/SECURITY.md](../../../docs/SECURITY.md), it must not facilitate betting, process payments, or present itself as a sportsbook. Users log and settle bets for record-keeping and analytics only.

---

## Glossary

- **BetEntry**: The domain entity representing one logged bet.
- **BetEntryX**: The computed-property extension for `potentialPayout`, `profitLoss`, and `isPending`.
- **BettingRepository**: The abstract domain contract for logging, settling, listing, and analyzing bets.
- **BettingRepositoryImpl**: The data-layer implementation that composes Drift, Firebase, and sync orchestration.
- **BettingLocalSource**: The Drift-backed source wrapping the existing `BetDao`.
- **BettingFirebaseSource**: The Firestore-backed source for `bet_entries` documents.
- **BettingScreen**: The main betting feed screen shown from the second bottom-nav tab.
- **LogBetScreen**: The form screen used to create a `BetEntry`.
- **RoiDashboard**: The analytics screen summarizing ROI, win rate, and profitability breakdowns.
- **BetType**: The existing enum for supported bet kinds such as `win`, `draw`, `btts`, `overUnder`, `correctScore`, `accumulator`, `moneyline`, and `prop`.
- **BetVisibility**: The existing enum controlling whether a bet is `public`, `friends`, or `private`.

---

## Requirements

### Requirement 1: Domain Layer Contracts

**User Story:** As a developer, I want pure domain entities, repository interfaces, failures, and use cases for betting, so that the feature remains testable and backend-agnostic.

#### Acceptance Criteria

1. THE `BetEntry` entity SHALL be a Freezed value object with fields matching [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md): `id`, `userId`, `sport`, `fixtureId`, `matchDescription`, `betType`, `prediction`, `odds`, `stake`, `currency`, `bookmaker`, `settled`, `won`, `payout`, `settledAt`, `visibility`, and `createdAt`.
2. THE `BetEntry` entity SHALL contain zero imports from Flutter framework packages, Firebase packages, or Drift packages.
3. THE `BetEntryX` extension SHALL expose `potentialPayout`, `profitLoss`, and `isPending` computed properties matching the formulas documented in [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md).
4. THE betting domain SHALL define a feature-scoped failure type that presentation code can render without inspecting Firebase or Drift exception classes directly.
5. THE `BettingRepository` interface SHALL declare `logBet`, `getEntries`, `watchEntries`, `getEntryById`, `settleBet`, and `calculateRoi` operations.
6. THE `LogBet`, `SettleBet`, and `CalculateRoi` use case classes SHALL each accept the repository via constructor injection and expose a single `call()` method.
7. FOR ALL valid `BetEntry` instances, serializing to and deserializing from JSON SHALL produce an equivalent entity.

---

### Requirement 2: Manual Bet Logging

**User Story:** As a user, I want to manually record a bet I already placed on an external bookmaker, so that I can track my real betting history in one place.

#### Acceptance Criteria

1. THE `LogBetScreen` SHALL collect the fields required to create a valid `BetEntry`: match context, `betType`, `prediction`, `odds`, `stake`, `bookmaker`, and `visibility`.
2. THE `LogBetScreen` SHALL default `currency` to `'NGN'` unless the user explicitly chooses another supported currency.
3. THE `LogBetScreen` SHALL create new entries with `settled = false`, `won = null`, `payout = null`, and `settledAt = null`.
4. THE feature SHALL present itself as a manual tracker and SHALL not initiate, process, or link out to a real-money betting transaction flow.
5. IF the user submits invalid odds, invalid stake, or missing required fields, THEN THE screen SHALL show field-level validation errors before any repository call is made.
6. WHILE a log-bet submission is in progress, THE `LogBetScreen` SHALL disable repeat submission and display a loading state.
7. THE `LogBetScreen` SHALL be able to accept future fixture context from the match-search feature without requiring the feature to exist first.

---

### Requirement 3: Offline-First Persistence

**User Story:** As a user with unreliable connectivity, I want logging or settling a bet to succeed immediately on my device, so that my tracking history remains usable offline.

#### Acceptance Criteria

1. WHEN `logBet` is called, THE repository SHALL write the new bet to the local `BetEntries` table via the existing `BetDao` before any remote operation is attempted.
2. WHEN the device is online and remote sync succeeds, THE repository SHALL mark the local row as synced.
3. WHEN the device is offline, or when a remote create fails after the local write succeeds, THE repository SHALL enqueue a pending `create` operation in `SyncQueue` with `collection = 'bet_entries'`.
4. WHEN `settleBet` is called, THE repository SHALL update the local row first, before attempting any remote update.
5. WHEN a remote settlement update fails after the local settlement succeeds, THE repository SHALL enqueue an `update` operation in `SyncQueue` with `collection = 'bet_entries'`.
6. THE local write path for logging and settling SHALL never depend on Firestore availability to report success on-device.
7. WHEN queued create or update operations later sync successfully, THE corresponding local rows SHALL be updated to reflect the synced state.

---

### Requirement 4: Firebase Sync

**User Story:** As a user, I want my bet history to sync across devices, so that my logged and settled bets remain available after reinstall or device switch.

#### Acceptance Criteria

1. THE remote source SHALL persist bet documents to the Firestore `bet_entries/{betId}` collection structure defined in [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md).
2. THE Firestore payload SHALL include `userId`, `sport`, `fixtureId`, `matchDescription`, `betType`, `prediction`, `odds`, `stake`, `currency`, `bookmaker`, `visibility`, `createdAt`, `updatedAt` when applicable, and settlement data when present.
3. WHEN a bet is unsettled, THE remote payload SHALL omit or null the result object fields rather than fabricating a result.
4. WHEN a bet is settled, THE remote payload SHALL represent the result using `won`, `payout`, and `settledAt` consistently with the documented schema.
5. IF a remote create or update fails, THEN THE repository SHALL preserve the locally written bet and queue the failed operation for retry.
6. Remote refresh merges SHALL be idempotent and SHALL not create duplicate local rows when the same payload is applied more than once.

---

### Requirement 5: Bet Feed

**User Story:** As a user, I want a fast, readable feed of all my bets, so that I can scan pending and settled positions quickly.

#### Acceptance Criteria

1. THE `BettingScreen` SHALL read from local Drift-backed data first and render without waiting for a remote round trip.
2. THE betting feed SHALL order bets by `createdAt` descending, with the newest entries shown first.
3. THE betting feed SHALL support filtering at minimum by `pending` and `settled`, as described in [docs/DESIGN.md](../../../docs/DESIGN.md).
4. THE `BettingScreen` SHALL render a `BetCard` per entry showing prediction, odds, result badge, bookmaker, stake, payout when available, league or match context, and date.
5. THE `BetCard` visual state SHALL distinguish won, lost, and pending entries using the semantic colors defined in the Phase 1 design system.
6. THE `BettingScreen` SHALL reuse the shared loading, empty, and error states from the foundation where applicable.
7. WHEN the user taps the floating action button on `BettingScreen`, THE app SHALL navigate to `LogBetScreen`.

---

### Requirement 6: Bet Settlement

**User Story:** As a user, I want to settle a logged bet when the match result is known, so that my profit/loss and ROI stay accurate.

#### Acceptance Criteria

1. THE betting feature SHALL provide a settlement flow for pending bets.
2. THE settlement flow SHALL require the user to choose whether the bet was won or lost.
3. WHEN the user settles a bet as won, THE flow SHALL require a non-negative `payout` value.
4. WHEN the user settles a bet as lost, THE flow SHALL set `payout` to `0` or an equivalent loss value defined consistently by the repository and tests.
5. WHEN the user completes settlement, THE repository SHALL update `settled = true`, set `won`, set `settledAt`, and persist the final `payout`.
6. IF a bet is already settled, THEN THE feature SHALL not allow duplicate settlement that would silently double-count ROI.
7. THE settlement flow SHALL update the local feed and ROI dashboard reactively after the local write succeeds.

---

### Requirement 7: ROI Dashboard

**User Story:** As a user, I want an ROI dashboard that shows whether my betting is actually profitable, so that I can understand patterns across leagues, bet types, and bookmakers.

#### Acceptance Criteria

1. THE `RoiDashboard` SHALL summarize at minimum: total bets, bets won, bets lost, bets pending, win rate, total staked, total payout, and ROI.
2. THE `RoiDashboard` SHALL compute ROI using the formula documented in [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md): `(totalPayout - totalStaked) / totalStaked * 100`.
3. THE dashboard SHALL expose profitability breakdowns for `roiByLeague`, `roiByBetType`, and `roiByBookmaker`.
4. THE dashboard SHALL identify and display the most profitable league, most profitable bet type, and least profitable bookmaker.
5. WHEN there are no settled bets, THE dashboard SHALL return safe zero or empty values instead of `NaN`, infinity, or crashes.
6. THE dashboard UI SHALL use the app's existing stat card and typography patterns, and SHALL render positive ROI in `success` colors and negative ROI in `error` colors.
7. WHEN league context is unavailable on a logged bet, THE ROI calculation SHALL bucket that entry under a deterministic fallback label such as `"Unknown"` rather than dropping it from league analytics.
8. THE dashboard SHALL include an ROI-over-time visualization aligned to the design language in [docs/DESIGN.md](../../../docs/DESIGN.md).

---

### Requirement 8: Visibility and Privacy

**User Story:** As a user, I want control over who can see my logged bets, so that I can keep my betting data private unless I choose otherwise.

#### Acceptance Criteria

1. THE `LogBetScreen` SHALL allow the user to choose `public`, `friends`, or `private` visibility for each bet.
2. THE feature SHALL default new bets to `BetVisibility.private_` unless the user explicitly changes the visibility.
3. THE betting feature SHALL build remote payloads that respect the chosen `visibility` field.
4. THE feature SHALL respect the Firestore security model defined in [docs/SECURITY.md](../../../docs/SECURITY.md): owners can always read their own bets, `public` bets are broadly readable to authenticated users, and `friends` bets depend on follow relationships.
5. THE local owner-facing betting feed SHALL always show the authenticated user's own bets regardless of visibility setting.
6. THE Phase 1 betting feed SHALL remain owner-centric; cross-user social bet feeds belong to later social features.

---

### Requirement 9: Routing and Riverpod Integration

**User Story:** As a developer, I want the betting feature wired into the existing provider graph and app router, so that the feature behaves consistently with the rest of the app.

#### Acceptance Criteria

1. THE betting feature SHALL expose Riverpod providers for the repository, core use cases, feed state, filter state, selected bet detail state, and ROI state.
2. THE `betEntriesProvider` SHALL expose the current user's bets as an `AsyncValue<List<BetEntry>>`.
3. THE ROI provider SHALL expose the current user's betting analytics as an `AsyncValue` model suitable for `RoiDashboard`.
4. THE betting feature SHALL derive the active `userId` from the authenticated user provider rather than passing it manually through widgets.
5. THE feature SHALL integrate with the existing named routes for betting and log bet, and SHALL add a dedicated ROI dashboard route if one is not already present.
6. THE feature SHALL remain compatible with the existing bottom navigation structure where Betting is tab 2.

---

### Requirement 10: Security and Compliance

**User Story:** As the app, I want the betting tracker implemented in a compliant, ownership-safe way, so that it does not drift into sportsbook behavior or expose one user's bets to another improperly.

#### Acceptance Criteria

1. THE betting feature SHALL only create, update, or delete remote `bet_entries` documents for the currently authenticated user.
2. THE feature SHALL never trust a widget-provided `userId` over the authenticated session when building remote mutation payloads.
3. THE feature SHALL not initiate bet placement, in-app wagering, payment flows, or bookmaker account linkage.
4. THE feature SHALL be framed in copy and structure as personal record-keeping and analytics, consistent with the app-store disclaimer in [docs/SECURITY.md](../../../docs/SECURITY.md).
5. THE feature SHALL not store API keys, tokens, or bookmaker credentials inside betting feature code, local payloads, or synced documents.
6. THE feature SHALL preserve ownership and visibility semantics when refreshing local data from Firestore.

---

### Requirement 11: Testing and Correctness Properties

**User Story:** As a developer, I want strong automated test coverage for logging, settlement, and ROI calculations, so that analytics regressions are caught early.

#### Acceptance Criteria

1. THE test suite SHALL include unit tests for `LogBet`, `SettleBet`, and `CalculateRoi`.
2. THE test suite SHALL include repository tests covering: local-first create, online create plus remote sync, offline create plus queueing, local-first settlement, offline settlement queueing, and local-first reads with remote refresh.
3. THE test suite SHALL include widget tests for `BettingScreen`, `LogBetScreen`, and `RoiDashboard`.
4. THE test suite SHALL include widget tests for `BetCard`, `OddsInput`, and `BookmakerSelector` behaviors that are critical to betting interactions.
5. FOR ALL valid `BetEntry` instances, JSON serialization followed by deserialization SHALL return an equivalent entity.
6. FOR ALL valid bets, THE computed `potentialPayout` SHALL equal `stake * odds`.
7. FOR ALL settled winning bets with valid payout, THE computed `profitLoss` SHALL equal `payout - stake`.
8. FOR ALL settled losing bets, THE computed `profitLoss` SHALL equal `-stake`.
9. FOR ALL empty or zero-stake aggregate cases, THE ROI calculator SHALL return zero-safe values without division-by-zero failures.
10. FOR ALL identical remote refresh payloads applied more than once, THE local betting cache merge SHALL be idempotent and SHALL not create duplicate entries.
