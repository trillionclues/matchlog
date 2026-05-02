# Implementation Tasks: Match Search

## Tasks

- [ ] 1. Spec and dependency alignment
  - [ ] 1.1 Treat `.kiro/specs/match-search/` as the canonical implementation spec for the match-search feature
  - [ ] 1.2 Confirm the project has the networking and caching dependencies already documented for Dio plus Drift-backed API caching
  - [ ] 1.3 Reuse existing Phase 1 foundation assets (`AppDatabase`, `FixtureCache`, Riverpod providers, routes, theme tokens, formatters, and shared UI states) instead of creating search-specific duplicates

- [ ] 2. Match-search domain layer
  - [ ] 2.1 Implement `lib/features/match_search/domain/entities/fixture.dart` as a Freezed model for searchable fixture context
  - [ ] 2.2 Implement lightweight `league.dart` and `team.dart` models only if they materially simplify filtering or mapping
  - [ ] 2.3 Implement `lib/features/match_search/domain/failures/fixture_failure.dart`
  - [ ] 2.4 Implement `lib/features/match_search/domain/repositories/fixture_repository.dart`
  - [ ] 2.5 Implement `lib/features/match_search/domain/usecases/search_fixtures.dart`

- [ ] 3. TheSportsDB source
  - [ ] 3.1 Implement `lib/features/match_search/data/football_api_source.dart` using TheSportsDB as the Phase 1 primary source
  - [ ] 3.2 Implement search via `searchevents.php`
  - [ ] 3.3 Implement upcoming-fixtures lookup via `eventsnext.php` if needed for prefill and future reuse
  - [ ] 3.4 Map upstream responses into `Fixture` entities with stable ids and optional badge or venue fields
  - [ ] 3.5 Return empty lists for no-result responses and surface transport failures for repository handling

- [ ] 4. Cache access and normalization
  - [ ] 4.1 Implement cache access on top of the existing `FixtureCache` table in `AppDatabase`
  - [ ] 4.2 Store successful results with a six-hour expiry window
  - [ ] 4.3 Add deterministic query normalization for trimming, whitespace collapse, and request deduplication
  - [ ] 4.4 Implement valid-cache reads, expired-cache refresh behavior, and stale-cache fallback
  - [ ] 4.5 Ensure repeated writes for the same `fixtureId` remain idempotent

- [ ] 5. Repository implementation
  - [ ] 5.1 Implement `lib/features/match_search/data/fixture_repository_impl.dart`
  - [ ] 5.2 Check cache before network for search and lookup flows
  - [ ] 5.3 Call TheSportsDB when fresh cache is missing or expired
  - [ ] 5.4 Return stale cached fixtures when network refresh fails
  - [ ] 5.5 Keep the repository abstraction open for a future secondary provider without requiring it for Phase 1

- [ ] 6. Riverpod providers and controllers
  - [ ] 6.1 Implement `lib/features/match_search/presentation/providers/fixture_search_providers.dart`
  - [ ] 6.2 Expose query state, league-filter state, and `fixtureSearchProvider`
  - [ ] 6.3 Debounce query changes at the provider or controller boundary
  - [ ] 6.4 Keep client-side filtering separate from repository fetch logic

- [ ] 7. Search UI
  - [ ] 7.1 Implement `lib/features/match_search/presentation/screens/search_screen.dart`
  - [ ] 7.2 Implement `lib/features/match_search/presentation/widgets/search_bar.dart`
  - [ ] 7.3 Implement `lib/features/match_search/presentation/widgets/league_filter.dart`
  - [ ] 7.4 Implement `lib/features/match_search/presentation/widgets/fixture_card.dart`
  - [ ] 7.5 Reuse shared loading, empty, and error states instead of duplicating them inside the feature
  - [ ] 7.6 Ensure selecting a fixture returns typed `Fixture` context to the caller

- [ ] 8. Router integration
  - [ ] 8.1 Add or wire a dedicated search route in the existing GoRouter configuration
  - [ ] 8.2 Ensure diary and betting can both navigate to the same search flow
  - [ ] 8.3 Return the selected `Fixture` via typed route extras or an equivalent typed navigation contract

- [ ] 9. Cross-feature handoff
  - [ ] 9.1 Define the fixture-selection contract so diary logging can prefill match context from search results
  - [ ] 9.2 Define the fixture-selection contract so bet logging can prefill match context from search results
  - [ ] 9.3 Keep the `Fixture` entity free of diary-specific and betting-specific validation rules

- [ ] 10. Testing
  - [ ] 10.1 Add unit tests for `Fixture` JSON round-trip and `SearchFixtures`
  - [ ] 10.2 Add API source tests for successful parsing, empty responses, and network failures
  - [ ] 10.3 Add repository tests for cache hit, cache expiry, successful refresh, stale-cache fallback, and no-cache failure behavior
  - [ ] 10.4 Add widget tests for `SearchScreen`, `SearchBar`, `LeagueFilter`, and `FixtureCard`
  - [ ] 10.5 Add a flow test confirming fixture selection can continue into a caller such as diary logging
  - [ ] 10.6 Add property-based tests for cache expiry semantics, idempotent cache writes, and query-normalization equivalence

- [ ] 11. Verification and cleanup
  - [ ] 11.1 Run `dart run build_runner build --delete-conflicting-outputs`
  - [ ] 11.2 Run `flutter test`
  - [ ] 11.3 Run `flutter analyze`
  - [ ] 11.4 Manually verify the core search flow: search fixture -> filter results -> select fixture -> return to caller
