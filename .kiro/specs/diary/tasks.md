# Implementation Tasks: Diary

## Tasks

- [ ] 1. Spec and dependency alignment
  - [ ] 1.1 Treat `.kiro/specs/diary/` as the canonical implementation spec for the diary feature
  - [ ] 1.2 Confirm the project has the Firebase packages needed for Firestore and Storage diary sync; add any missing diary dependencies before implementation
  - [ ] 1.3 Reuse existing Phase 1 foundation assets (`AppDatabase`, `MatchDao`, shared widgets, validators, formatters, routes, and theme tokens) instead of creating diary-specific duplicates

- [ ] 2. Diary domain layer
  - [ ] 2.1 Implement `lib/features/diary/domain/entities/match_entry.dart` as a Freezed model matching the documented schema
  - [ ] 2.2 Implement `lib/features/diary/domain/entities/user_stats.dart` matching the documented computed stats model
  - [ ] 2.3 Implement `lib/features/diary/domain/failures/diary_failure.dart`
  - [ ] 2.4 Implement `lib/features/diary/domain/repositories/diary_repository.dart`
  - [ ] 2.5 Implement use cases for `log_match`, `get_diary_entries`, `delete_entry`, and `calculate_stats`

- [ ] 3. Local data source
  - [ ] 3.1 Implement `lib/features/diary/data/diary_local_source.dart` on top of the existing `MatchDao`
  - [ ] 3.2 Add local queries for feed ordering, filter handling, entry lookup by id, delete, and synced-state updates
  - [ ] 3.3 Ensure local reads are the default path for feed and detail screens

- [ ] 4. Firebase data source
  - [ ] 4.1 Implement `lib/features/diary/data/diary_firebase_source.dart` for Firestore `match_entries` create, fetch, and delete operations
  - [ ] 4.2 Implement Firebase Storage photo upload under `users/{userId}/match_photos/{entryId}/`
  - [ ] 4.3 Implement remote mapping between Firestore documents and the domain `MatchEntry`
  - [ ] 4.4 Keep `geoVerified` read-only from this feature and default new entries to `false`

- [ ] 5. Repository and sync orchestration
  - [ ] 5.1 Implement `lib/features/diary/data/diary_repository_impl.dart`
  - [ ] 5.2 Write locally first for new entries, then sync remotely when online
  - [ ] 5.3 Queue `match_entries` create operations in `SyncQueue` when offline or when remote sync fails
  - [ ] 5.4 Merge remote refreshes back into Drift without duplicating existing entries
  - [ ] 5.5 Implement local-first delete with online delete or queued delete fallback
  - [ ] 5.6 Rewrite local photo paths to remote Storage URLs after successful sync

- [ ] 6. Stats aggregation
  - [ ] 6.1 Implement diary-derived stats: totals, monthly count, league/team/watch-type breakdowns, average rating, stadium visits, current streak, and longest streak
  - [ ] 6.2 Wire betting-derived `UserStats` fields through abstract repository reads so the diary feature stays decoupled from concrete betting data code
  - [ ] 6.3 Ensure all stats calculations are zero-safe and deterministic

- [ ] 7. Riverpod providers and controllers
  - [ ] 7.1 Implement `lib/features/diary/presentation/providers/diary_providers.dart`
  - [ ] 7.2 Implement `lib/features/diary/presentation/providers/stats_providers.dart`
  - [ ] 7.3 Expose `diaryEntriesProvider` and `statsProvider` as `AsyncValue`-based feature providers
  - [ ] 7.4 Add filter state and log-match mutation controller providers
  - [ ] 7.5 Derive the active `userId` from auth providers instead of passing it through widgets

- [ ] 8. Diary screens
  - [ ] 8.1 Implement `lib/features/diary/presentation/screens/diary_screen.dart`
  - [ ] 8.2 Implement `lib/features/diary/presentation/screens/log_match_screen.dart`
  - [ ] 8.3 Implement `lib/features/diary/presentation/screens/match_detail_screen.dart`
  - [ ] 8.4 Implement `lib/features/diary/presentation/screens/stats_dashboard.dart`
  - [ ] 8.5 Make the log-match screen accept selected fixture context from the future `match-search` flow via route extras or an equivalent typed contract

- [ ] 9. Diary widgets
  - [ ] 9.1 Implement `lib/features/diary/presentation/widgets/match_card.dart`
  - [ ] 9.2 Implement `lib/features/diary/presentation/widgets/rating_stars.dart`
  - [ ] 9.3 Implement `lib/features/diary/presentation/widgets/watch_type_selector.dart`
  - [ ] 9.4 Implement `lib/features/diary/presentation/widgets/stat_card.dart`
  - [ ] 9.5 Reuse shared `photo_grid.dart`, `empty_state.dart`, `error_state.dart`, and `loading_shimmer.dart` instead of duplicating them inside the feature

- [ ] 10. Router integration
  - [ ] 10.1 Wire the diary screens into the existing named routes for diary, log match, match detail, and stats
  - [ ] 10.2 Ensure the diary FAB navigates to the log-match route and match cards navigate to the detail route
  - [ ] 10.3 Ensure the stats entry point routes to the stats dashboard without duplicating auth redirect logic

- [ ] 11. Testing
  - [ ] 11.1 Add unit tests for `MatchEntry` JSON round-trip and the diary use cases
  - [ ] 11.2 Add repository tests for online create, offline queueing, remote merge, delete fallback, and photo upload reconciliation
  - [ ] 11.3 Add widget tests for `DiaryScreen`, `LogMatchScreen`, `MatchDetailScreen`, and `StatsDashboard`
  - [ ] 11.4 Add widget tests for `MatchCard`, `RatingStars`, and `WatchTypeSelector`
  - [ ] 11.5 Add property-based tests for stats invariants: watch-type totals, average rating bounds, streak ordering, zero-input safety, and idempotent remote merges

- [ ] 12. Verification and cleanup
  - [ ] 12.1 Run `dart run build_runner build --delete-conflicting-outputs`
  - [ ] 12.2 Run `flutter test`
  - [ ] 12.3 Run `flutter analyze`
  - [ ] 12.4 Manually verify the core diary flow: log match -> view feed -> open detail -> view stats
