# Design Document: Match Search

## Overview

The match-search feature gives the app a reusable fixture picker backed by real sports data. In Phase 1, that means:

1. TheSportsDB is the primary external data source
2. Drift `FixtureCache` is the first read path
3. Riverpod owns query and result state
4. GoRouter handles entry into the search flow and returning a selected fixture
5. diary and betting consume the same typed `Fixture` output

This is an integration-heavy feature, but not a user-generated sync feature. It should use local caching aggressively and avoid pulling Firestore or SyncQueue into the design.

---

## Architecture

### Layering

```text
Presentation  ->  Domain  <-  Data
                   ^          ^
                   |          |
                 Core    Dio + Drift FixtureCache
```

- `domain/` stays pure Dart and defines the fixture contract, repository, failures, and use cases
- `data/` maps TheSportsDB responses and manages cache-aware repository behavior
- `presentation/` owns the search UI and selection interactions
- `core/` supplies `AppDatabase`, API configuration, routing, formatters, and DI

### File Structure

```text
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart
│   ├── database/
│   │   └── app_database.dart
│   ├── di/
│   │   └── providers.dart
│   └── router/
│       ├── app_router.dart
│       └── routes.dart
│
└── features/
    └── match_search/
        ├── data/
        │   ├── fixture_repository_impl.dart
        │   └── football_api_source.dart
        ├── domain/
        │   ├── entities/
        │   │   ├── fixture.dart
        │   │   ├── league.dart
        │   │   └── team.dart
        │   ├── failures/
        │   │   └── fixture_failure.dart
        │   ├── repositories/
        │   │   └── fixture_repository.dart
        │   └── usecases/
        │       └── search_fixtures.dart
        └── presentation/
            ├── providers/
            │   └── fixture_search_providers.dart
            ├── screens/
            │   └── search_screen.dart
            └── widgets/
                ├── fixture_card.dart
                ├── league_filter.dart
                └── search_bar.dart
```

### Enum Reuse

The architecture sketch mentions a feature-local `sport.dart`, but the completed foundation already centralizes `Sport` in core/shared enum definitions. This feature should reuse the existing `Sport` enum rather than creating another copy.

---

## Domain Design

### `Fixture`

`Fixture` is the typed output of the feature and the handoff object for diary and betting.

Recommended shape:

```dart
@freezed
class Fixture with _$Fixture {
  const factory Fixture({
    required String id,
    required Sport sport,
    required String homeTeam,
    required String awayTeam,
    required String league,
    required DateTime date,
    String? time,
    String? venue,
    String? homeTeamBadge,
    String? awayTeamBadge,
  }) = _Fixture;
}
```

Design notes:

- keep the entity minimal but sufficient to drive diary and betting prefill
- preserve upstream event ids exactly so cache, lookup, and handoff stay stable
- make `venue` and badge URLs optional because upstream data may omit them

### Optional Supporting Entities

`League` and `Team` may remain lightweight pure Dart models if useful for display or future expansion. In Phase 1 they should stay subordinate to `Fixture` and not introduce unnecessary complexity.

### `FixtureFailure`

The failure union should hide Dio and parsing details from widgets. Useful variants include:

- `emptyQuery`
- `network`
- `rateLimited`
- `cacheMiss`
- `parsing`
- `unknown`

Each variant should expose presentation-safe messaging.

### Repository Contract

The repository API should look roughly like this:

```dart
abstract interface class FixtureRepository {
  Future<List<Fixture>> searchFixtures({
    required String query,
    Sport sport = Sport.football,
  });
  Future<List<Fixture>> getUpcomingFixtures({
    required String teamId,
    Sport sport = Sport.football,
  });
  Future<List<Fixture>> getCachedFixtures({
    String? queryKey,
    String? teamId,
    bool includeExpired = false,
  });
  Future<Fixture?> getFixtureById(String fixtureId);
}
```

Phase 1 is football-first, but the contract should not block later sport plugins.

---

## Data Layer Design

### `FootballApiSource`

`FootballApiSource` is the TheSportsDB adapter in Phase 1.

Responsibilities:

- call `searchevents.php` for free-text fixture search
- call `eventsnext.php` for team-based upcoming fixtures when needed
- map upstream payloads to `Fixture`
- return empty lists when the upstream response contains no events
- let transport failures surface so repository fallback logic can decide how to respond

The source should not know about Riverpod, widgets, or cache policy.

### Cache Strategy

The completed foundation already includes a `FixtureCache` Drift table:

- `fixtureId`
- `teamId`
- `data`
- `cachedAt`
- `expiresAt`

That schema is fixture-centric, not query-centric. The Phase 1 implementation therefore needs a deterministic cache strategy:

1. cache each returned fixture row by `fixtureId`
2. persist `teamId` when the source query is team-based
3. for text search, maintain a deterministic query-key mapping strategy in the repository or companion cache metadata layer so repeated normalized queries can reuse cached fixture sets
4. respect a six-hour TTL for fresh cache reads

If the implementation chooses not to add a second cache index table in Phase 1, the minimum acceptable behavior is:

- cache returned fixtures individually
- reuse cached fixture details by id
- allow stale fallback when a repeated text search fails but prior mapped results are still recoverable

### `FixtureRepositoryImpl`

`FixtureRepositoryImpl` composes:

- `FootballApiSource` as the Phase 1 primary source
- `AppDatabase` access to `FixtureCache`
- any lightweight query-normalization helper needed for cache reuse

#### Search Path

```text
User types query
  -> SearchFixtures use case
  -> FixtureRepositoryImpl.searchFixtures
  -> normalize query
  -> check valid local cache for that query/result set
  -> if valid cache hit: return cached fixtures
  -> else call TheSportsDB
  -> cache returned fixtures with 6h expiry
  -> return results
```

#### Fallback Path

```text
network request fails
  -> check stale cached results for the normalized query
  -> if stale cache exists: return it
  -> else surface failure
```

#### Lookup Path

```text
calling feature reopens a selected fixture
  -> getFixtureById(fixtureId)
  -> check FixtureCache first
  -> if missing and network-capable lookup exists, fetch upstream
  -> store in cache
  -> return Fixture?
```

### Query Normalization

To avoid unnecessary duplicate calls, normalize query input before caching or searching:

- trim leading and trailing whitespace
- collapse repeated internal whitespace
- treat empty normalized queries as non-searchable

If case-folding is used, apply it consistently to both cache lookup and request deduplication.

---

## Presentation Design

### `SearchScreen`

The search screen is a reusable picker, not a destination users browse aimlessly.

Layout:

- app bar with context-aware title such as "Search Match"
- top `SearchBar`
- optional `LeagueFilter` row when multiple leagues are present in results
- scrollable list of `FixtureCard`
- shared empty or error states as fallbacks

Behavior:

- no request on empty query
- debounced search after typing begins
- results update reactively through Riverpod
- selecting a fixture returns to the caller with a typed result

### `SearchBar`

The search input should:

- accept match, club, or fixture text
- debounce change events
- expose clear/reset affordances
- avoid search-side effects for blank queries

### `FixtureCard`

The result card should present:

- home and away teams
- league
- kickoff date and time
- venue when present
- badges when present

It should feel consistent with the diary card density and theme rather than looking like a separate mini-app.

### `LeagueFilter`

This control should derive its options from the current result set rather than from hardcoded external configuration. It is a client-side result refinement layer, not a separate API call trigger in Phase 1.

---

## Provider Design

Expected Riverpod surface:

- `fixtureRepositoryProvider`
- `searchFixturesProvider`
- `fixtureSearchQueryProvider`
- `fixtureLeagueFilterProvider`
- `fixtureSearchProvider(query)`
- `selectedFixtureProvider` if local selection state is needed

Design notes:

- keep query state separate from result state
- debounce at the provider/controller boundary rather than in the repository
- keep filtering client-side once results are loaded

---

## Routing Integration

The feature should be reachable through a dedicated search route such as `Routes.search`, unless the core router already has an equivalent route.

Routing rules:

- diary and betting can both push the same search route
- selection returns a typed `Fixture` payload to the caller
- the route should not be duplicated per feature

Auth guards remain owned by the app's core router.

---

## Rate Limits and Failover

Relevant source constraints:

- TheSportsDB is the Phase 1 primary source
- free tier is rate-limited but generous enough for user-facing search with caching
- API-Football exists as a broader architecture fallback but is not required to ship this feature

Implementation decisions:

- prefer valid cache over requerying
- debounce search input aggressively enough to avoid per-keystroke network calls
- use stale cache as a graceful fallback when the network fails
- keep the repository abstraction open for a future secondary provider

---

## Testing Strategy

### Unit Tests

- `search_fixtures_test.dart`
- `fixture_test.dart` for JSON round-trip
- `football_api_source_test.dart`

### Repository Tests

- valid cache hit returns cache and skips network
- expired cache triggers refresh
- successful refresh rewrites cache with new expiry
- network failure with stale cache returns stale cache
- network failure without any cache surfaces failure

### Widget Tests

- `search_screen_test.dart`
- `widgets/search_bar_test.dart`
- `widgets/league_filter_test.dart`
- `widgets/fixture_card_test.dart`

### Property-Based Correctness

Properties that should be tested with generated inputs where practical:

1. `Fixture` JSON round-trip preserves equality
2. future `expiresAt` values count as valid cache hits
3. past `expiresAt` values count as expired for fresh reads
4. repeated writes for the same `fixtureId` remain idempotent in cache
5. query normalization maps equivalent whitespace variants to the same cache behavior
