# Implementation Tasks: Betting

## Tasks

- [ ] 1. Spec and dependency alignment
  - [ ] 1.1 Treat `.kiro/specs/betting/` as the canonical implementation spec for the betting feature
  - [ ] 1.2 Confirm the project has the Firebase packages needed for Firestore bet sync; add any missing betting dependencies before implementation
  - [ ] 1.3 Reuse existing Phase 1 foundation assets (`AppDatabase`, `BetDao`, sync queue, formatters, validators, routes, theme tokens, and shared widgets) instead of creating betting-specific duplicates

- [ ] 2. Betting domain layer
  - [ ] 2.1 Implement `lib/features/betting/domain/entities/bet_entry.dart` as a Freezed model matching the documented schema
  - [ ] 2.2 Implement computed properties for `potentialPayout`, `profitLoss`, and `isPending`
  - [ ] 2.3 Implement `lib/features/betting/domain/failures/betting_failure.dart`
  - [ ] 2.4 Implement `lib/features/betting/domain/repositories/betting_repository.dart`
  - [ ] 2.5 Implement use cases for `log_bet`, `settle_bet`, and `calculate_roi`

- [ ] 3. Local data source
  - [ ] 3.1 Implement `lib/features/betting/data/betting_local_source.dart` on top of the existing `BetDao`
  - [ ] 3.2 Add local queries for feed ordering, pending or settled filtering, bet lookup by id, settlement updates, and synced-state updates
  - [ ] 3.3 Ensure local reads are the default path for betting feed and ROI calculations

- [ ] 4. Firebase data source
  - [ ] 4.1 Implement `lib/features/betting/data/betting_firebase_source.dart` for Firestore `bet_entries` create, fetch, update, and delete operations
  - [ ] 4.2 Implement remote mapping between Firestore documents and the domain `BetEntry`
  - [ ] 4.3 Preserve `visibility` semantics exactly as documented in the security rules
  - [ ] 4.4 Keep the feature manual-only and avoid any real-money bet-placement integration

- [ ] 5. Repository and sync orchestration
  - [ ] 5.1 Implement `lib/features/betting/data/betting_repository_impl.dart`
  - [ ] 5.2 Write locally first for new bet entries, then sync remotely when online
  - [ ] 5.3 Queue `bet_entries` create operations in `SyncQueue` when offline or when remote create fails
  - [ ] 5.4 Implement local-first settlement with online update or queued update fallback
  - [ ] 5.5 Merge remote refreshes back into Drift without duplicating or double-settling existing entries
  - [ ] 5.6 Reject duplicate settlement attempts for already-settled bets

- [ ] 6. ROI analytics
  - [ ] 6.1 Implement total counts for bets, wins, losses, and pending
  - [ ] 6.2 Implement total staked, total payout, win rate, and ROI calculations
  - [ ] 6.3 Implement profitability breakdowns by league, bet type, and bookmaker
  - [ ] 6.4 Implement best and worst profitability summaries
  - [ ] 6.5 Ensure all analytics are zero-safe and deterministic
  - [ ] 6.6 Use fixture-derived league context when available and bucket unresolved entries under `Unknown` so `roiByLeague` remains total-preserving
  - [ ] 6.7 Keep aggregate outputs compatible with the diary feature's `UserStats` model

- [ ] 7. Riverpod providers and controllers
  - [ ] 7.1 Implement `lib/features/betting/presentation/providers/betting_providers.dart`
  - [ ] 7.2 Expose `betEntriesProvider` and ROI providers as `AsyncValue`-based feature providers
  - [ ] 7.3 Add feed-filter state and mutation controller providers for logging and settlement
  - [ ] 7.4 Derive the active `userId` from auth providers instead of passing it through widgets

- [ ] 8. Betting screens
  - [ ] 8.1 Implement `lib/features/betting/presentation/screens/betting_screen.dart`
  - [ ] 8.2 Implement `lib/features/betting/presentation/screens/log_bet_screen.dart`
  - [ ] 8.3 Implement `lib/features/betting/presentation/screens/roi_dashboard.dart`
  - [ ] 8.4 Add a settlement interaction for pending bets, using either a dedicated screen or a modal or sheet
  - [ ] 8.5 Make the log-bet screen accept selected fixture context from the future `match-search` flow via route extras or an equivalent typed contract

- [ ] 9. Betting widgets
  - [ ] 9.1 Implement `lib/features/betting/presentation/widgets/bet_card.dart`
  - [ ] 9.2 Implement `lib/features/betting/presentation/widgets/odds_input.dart`
  - [ ] 9.3 Implement `lib/features/betting/presentation/widgets/bookmaker_selector.dart`
  - [ ] 9.4 Implement `lib/features/betting/presentation/widgets/roi_breakdown.dart`
  - [ ] 9.5 Reuse shared loading, empty, and error states instead of duplicating them inside the feature

- [ ] 10. Router integration
  - [ ] 10.1 Wire the betting screens into the existing named routes for betting and log bet
  - [ ] 10.2 Add a dedicated ROI dashboard route if the core router does not already provide one
  - [ ] 10.3 Ensure the betting FAB navigates to the log-bet route and the ROI entry point navigates to the ROI dashboard
  - [ ] 10.4 Keep auth and redirect behavior centralized in the existing router guard layer

- [ ] 11. Compliance and UX refinements
  - [ ] 11.1 Audit feature copy to ensure the UI frames the feature as manual record-keeping and analytics
  - [ ] 11.2 Ensure new bets default to private visibility unless the user changes it
  - [ ] 11.3 Ensure loading states disable repeat submit and repeat settlement interactions
  - [ ] 11.4 Ensure validation prevents invalid odds, stake, payout, or incomplete settlement payloads before repository calls

- [ ] 12. Testing
  - [ ] 12.1 Add unit tests for `BetEntry` JSON round-trip and computed properties
  - [ ] 12.2 Add unit tests for `log_bet`, `settle_bet`, and `calculate_roi`
  - [ ] 12.3 Add repository tests for online create, offline queueing, online settlement, offline settlement queueing, and remote merge behavior
  - [ ] 12.4 Add widget tests for `BettingScreen`, `LogBetScreen`, and `RoiDashboard`
  - [ ] 12.5 Add widget tests for `BetCard`, `OddsInput`, and `BookmakerSelector`
  - [ ] 12.6 Add property-based tests for payout, profit/loss, zero-safe ROI, and idempotent remote merges

- [ ] 13. Verification and cleanup
  - [ ] 13.1 Run `dart run build_runner build --delete-conflicting-outputs`
  - [ ] 13.2 Run `flutter test`
  - [ ] 13.3 Run `flutter analyze`
  - [ ] 13.4 Manually verify the core betting flow: log bet -> settle bet -> inspect ROI dashboard
