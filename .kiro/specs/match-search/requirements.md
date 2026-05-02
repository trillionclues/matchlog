# Requirements Document

## Introduction

The Match Search feature lets users find fixtures before logging a diary entry or bet. It uses TheSportsDB as the Phase 1 primary fixture source and Drift `FixtureCache` as the local cache layer so searches remain fast, rate-limit-aware, and resilient to unreliable networks. This feature exists to support the rest of the app: users should be able to search once, pick a fixture, and carry that fixture context into diary and betting flows.

This feature builds on the completed Phase 1 foundation and the earlier specs:

1. `AppDatabase` and the existing `FixtureCache` table provide local cache persistence
2. Riverpod providers carry repository, query, and result state
3. GoRouter owns navigation into and out of the search flow
4. Existing design tokens, formatters, and shared loading or empty states must be reused
5. The selected fixture contract must be compatible with the diary and betting features

Phase 1 scope is TheSportsDB-first search with Drift caching. The architecture may remain ready for API-Football fallback later, but this spec does not require premium or secondary provider behavior to ship the feature.

---

## Glossary

- **Fixture**: The domain entity representing a searchable sports event or match.
- **FixtureRepository**: The abstract domain contract for searching, caching, and retrieving fixtures.
- **FixtureRepositoryImpl**: The data-layer implementation that composes Drift cache access with TheSportsDB API calls.
- **FootballApiSource**: The TheSportsDB-backed HTTP source for searching and fetching fixtures in Phase 1.
- **FixtureCache**: The existing Drift table that stores cached fixture payloads with expiry timestamps.
- **SearchScreen**: The fixture-search screen used by diary and betting flows.
- **FixtureCard**: The result card showing a searchable fixture summary.
- **LeagueFilter**: The filter control used to narrow visible results by league.
- **SearchBar**: The query input used to drive fixture search.

---

## Requirements

### Requirement 1: Domain Layer Contracts

**User Story:** As a developer, I want clear domain entities and repository contracts for fixture search, so that search can be tested in isolation and swapped to different sports or providers later.

#### Acceptance Criteria

1. THE match-search domain SHALL define a pure Dart `Fixture` entity containing the fields needed by search, diary, and betting flows: `id`, `sport`, `homeTeam`, `awayTeam`, `league`, `date`, `time`, `venue`, `homeTeamBadge`, and `awayTeamBadge`.
2. THE `Fixture` entity SHALL contain zero imports from Flutter framework packages, Firebase packages, or Drift packages.
3. THE feature MAY define pure Dart `League` and `Team` entities if needed by filtering or future provider expansion, but SHALL not duplicate the core `Sport` enum already established in the Phase 1 foundation.
4. THE match-search domain SHALL define a feature-scoped failure type that presentation code can render without inspecting Dio or Drift exceptions directly.
5. THE `FixtureRepository` interface SHALL declare `searchFixtures`, `getUpcomingFixtures`, `getCachedFixtures`, and `getFixtureById` operations suitable for Phase 1 search and future reuse.
6. THE use case surface SHALL include a `SearchFixtures` use case and any additional cache-aware lookup use case needed to support fixture selection.
7. FOR ALL valid `Fixture` instances, serializing to and deserializing from JSON SHALL produce an equivalent entity.

---

### Requirement 2: TheSportsDB Search Integration

**User Story:** As a user, I want search results sourced from real fixture data, so that I can select the correct match instead of typing raw match names manually.

#### Acceptance Criteria

1. THE match-search feature SHALL use TheSportsDB as the Phase 1 primary API source, consistent with [docs/API_INTEGRATIONS.md](../../../docs/API_INTEGRATIONS.md).
2. THE TheSportsDB source SHALL support text-based fixture search using the documented `searchevents.php` endpoint.
3. THE TheSportsDB source SHALL map successful API responses into `Fixture` entities with stable `id` values from the upstream event id.
4. WHEN the API returns no matching events, THE source SHALL return an empty list rather than throwing.
5. WHEN the API request fails due to network or timeout errors, THE source SHALL surface a failure that the repository can convert into a user-safe fallback or message.
6. THE feature SHALL stay compatible with the broader architecture abstraction where additional sports or secondary providers may be added later.

---

### Requirement 3: Drift Cache Strategy

**User Story:** As a user on a constrained connection, I want repeated searches and fixture lookups to reuse local cache where possible, so that the feature feels fast and stays within API limits.

#### Acceptance Criteria

1. THE feature SHALL use the existing `FixtureCache` Drift table as its local cache store.
2. EACH cached fixture row SHALL persist `fixtureId`, serialized response `data`, `cachedAt`, and `expiresAt` as defined in [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md).
3. WHEN fixtures are cached from a successful API response, THE repository SHALL set `expiresAt` to `cachedAt + 6 hours`, matching the strategy in [docs/API_INTEGRATIONS.md](../../../docs/API_INTEGRATIONS.md).
4. WHEN a non-expired cached result set satisfies the query or lookup, THE repository SHALL return cached fixtures without hitting the network.
5. WHEN cached entries are expired, THE repository SHALL attempt a fresh network fetch before reusing them.
6. WHEN the network fetch fails and expired cache exists, THE repository SHALL return stale cached fixtures rather than failing hard.
7. WHEN neither valid cache nor stale cache exists and the network request fails, THE repository SHALL surface a user-safe failure state.

---

### Requirement 4: Search Behavior

**User Story:** As a user, I want a responsive fixture search screen, so that I can quickly find the match I want and continue my logging flow.

#### Acceptance Criteria

1. THE `SearchScreen` SHALL provide a search bar for fixture text queries.
2. THE screen SHALL avoid issuing API searches for empty or whitespace-only queries.
3. THE screen SHALL debounce rapid query changes so typing does not trigger unnecessary API requests.
4. THE screen SHALL display result cards for matching fixtures including team names, league, kickoff date or time, venue when available, and team badges when available.
5. THE screen SHALL allow optional league-based filtering of visible results through a `LeagueFilter` control.
6. THE screen SHALL reuse the Phase 1 design system and shared loading, empty, and error patterns rather than introducing a parallel visual language.
7. WHEN the user selects a result, THE feature SHALL return that `Fixture` context to the calling flow in a form usable by diary and betting screens.

---

### Requirement 5: Local-First Reads and Offline Fallback

**User Story:** As a user without current connectivity, I want previously searched fixtures to remain selectable, so that I can still log a match or bet from known data.

#### Acceptance Criteria

1. THE repository SHALL check local cache before making a remote request for any cacheable fixture search or upcoming-fixtures lookup.
2. WHEN the device is offline and matching cached fixtures exist, THE feature SHALL show those cached results.
3. WHEN the device is offline and no matching cached fixtures exist, THE feature SHALL render a recoverable empty or offline state rather than crashing.
4. THE local-first behavior SHALL apply both to free-text search reuse and to fixture lookup by id when a selected fixture needs to be reopened.
5. THE feature SHALL not use Firestore or SyncQueue for fixture search results, because this is API caching rather than user-authored sync data.

---

### Requirement 6: Result Selection Contract

**User Story:** As a developer, I want a stable fixture-selection contract, so that diary and betting flows can consume search results without duplicating search logic.

#### Acceptance Criteria

1. THE match-search feature SHALL expose a typed result contract based on the `Fixture` entity rather than returning loosely structured maps through navigation.
2. WHEN a fixture is selected from `SearchScreen`, THE app SHALL be able to pass that fixture into `LogMatchScreen` or `LogBetScreen` via GoRouter `extra` or an equivalent typed mechanism.
3. THE `Fixture` contract SHALL include enough fields to populate diary and betting forms without forcing an immediate follow-up API call.
4. THE match-search feature SHALL not embed diary-specific or betting-specific validation rules into the `Fixture` entity itself.
5. THE selection contract SHALL remain stable even if the internal API provider changes later.

---

### Requirement 7: Routing and Riverpod Integration

**User Story:** As a developer, I want search state and navigation wired into the existing app infrastructure, so that the feature behaves like a first-class part of the app.

#### Acceptance Criteria

1. THE feature SHALL expose Riverpod providers for the repository, search use case, query state, league-filter state, and search results state.
2. THE `fixtureSearchProvider` SHALL expose search results as an `AsyncValue<List<Fixture>>`, consistent with the provider hierarchy outlined in [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md).
3. THE feature SHALL use the shared `AppDatabase` instance from the existing provider graph for cache reads and writes.
4. THE feature SHALL integrate with GoRouter through a dedicated search route if one does not already exist.
5. THE search flow SHALL support being opened from diary and betting screens without creating separate duplicated search screens.
6. THE feature SHALL keep query parsing, caching, and API work in providers or repositories rather than inside widgets.

---

### Requirement 8: API Rate Limits and Query Hygiene

**User Story:** As the app, I want search requests minimized and predictable, so that free-tier API limits are respected.

#### Acceptance Criteria

1. THE feature SHALL be designed around TheSportsDB's free-tier rate limit characteristics documented in [docs/API_INTEGRATIONS.md](../../../docs/API_INTEGRATIONS.md).
2. THE feature SHALL debounce text input before hitting the API.
3. THE feature SHALL not fire duplicate network requests for the same normalized query while a valid cache entry exists.
4. THE repository SHALL normalize cache keys or lookup behavior so trivial query variations do not cause avoidable repeated fetches.
5. THE feature SHALL prefer cached results over secondary refreshes whenever the cache is still valid.
6. THE feature MAY keep the repository abstraction ready for future API-Football fallback, but SHALL not require that fallback for Phase 1 completion.

---

### Requirement 9: Testing and Correctness Properties

**User Story:** As a developer, I want strong automated test coverage for API parsing, cache behavior, and selection flow, so that the search feature remains dependable.

#### Acceptance Criteria

1. THE test suite SHALL include unit tests for the TheSportsDB source covering successful parsing, empty results, and network failure behavior.
2. THE test suite SHALL include repository tests covering cache hit, cache expiry, successful refresh, stale-cache fallback on network failure, and miss-with-failure behavior.
3. THE test suite SHALL include widget tests for `SearchScreen`, `SearchBar`, `LeagueFilter`, and `FixtureCard`.
4. THE test suite SHALL include a widget or integration-level test confirming that selecting a fixture can continue into a calling flow such as diary logging.
5. FOR ALL valid `Fixture` instances, JSON serialization followed by deserialization SHALL return an equivalent entity.
6. FOR ALL cache entries with `expiresAt` in the future, THE repository SHALL treat them as valid cache hits.
7. FOR ALL cache entries with `expiresAt` in the past, THE repository SHALL treat them as expired for fresh-read purposes while still allowing stale fallback when network requests fail.
8. FOR ALL identical remote payloads cached more than once, THE cache write behavior SHALL be idempotent and SHALL not create duplicate rows for the same `fixtureId`.
