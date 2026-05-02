# Requirements Document

## Introduction

The Social feature introduces MatchLog's Phase 2 social layer: users can follow and unfollow each other, view an activity feed built from friend actions, browse user profiles, and explore followers or following lists. This is the first true social amplification step after the solo diary and betting loops described in [docs/PROJECT.md](../../../docs/PROJECT.md).

This feature builds on the completed Phase 1 and Phase 1.5 foundations:

1. auth already provides verified-email state and route guards
2. diary and betting already define the user actions that later appear in social activity
3. `UserProfiles` and `Follows` already exist in the local Drift schema
4. Firestore security rules already define ownership rules for `follows` and read-only `activity_feed`
5. notification settings already include a `socialActivity` preference hook

This feature must preserve the product sequencing principle: useful solo before social. The social layer amplifies existing user activity; it does not replace the diary-first product identity.

---

## Glossary

- **UserProfile**: The social-facing representation of another user's profile data, derived from user records plus privacy settings.
- **FollowRelationship**: The domain entity representing one follow edge between a follower and a followed user.
- **ActivityItem**: The domain entity representing one activity-feed item generated from user actions.
- **SocialRepository**: The abstract domain contract for follow actions, profile lookup, discovery, and feed reads.
- **SocialRepositoryImpl**: The data-layer implementation that composes Firestore with local caches where available.
- **SocialFirebaseSource**: The Firebase-backed source for follows, profiles, and the activity feed.
- **FeedScreen**: The main social activity feed screen.
- **ProfileScreen**: The screen for viewing another user's profile and recent activity.
- **FollowersScreen**: The list screen for followers or following relationships.
- **UserSearchScreen**: The discovery screen for finding users to follow.

---

## Requirements

### Requirement 1: Domain Layer Contracts

**User Story:** As a developer, I want clear social entities, repository contracts, failures, and use cases, so that the social layer remains testable and backend-agnostic.

#### Acceptance Criteria

1. THE social domain SHALL define a pure Dart `UserProfile` entity suitable for public or friend-visible profile rendering, drawing from the documented user fields and privacy settings.
2. THE `UserProfile` entity SHALL include at minimum: `userId`, `displayName`, `photoUrl`, `favoriteSport`, `favoriteTeam`, `followerCount`, `followingCount`, and whatever privacy-derived visibility flags are required to render the profile safely.
3. THE social domain SHALL define a pure Dart `FollowRelationship` entity with `followerId`, `followingId`, and `createdAt`.
4. THE social domain SHALL define a pure Dart `ActivityItem` entity matching [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md): `id`, `userId`, `displayName`, `userPhotoUrl`, `type`, `referenceId`, `summary`, and `createdAt`.
5. THE social domain SHALL define a feature-scoped failure type that presentation code can render without inspecting Firebase or Drift exceptions directly.
6. THE `SocialRepository` interface SHALL declare operations for `followUser`, `unfollowUser`, `getFeed`, `getUserProfile`, `getFollowers`, `getFollowing`, and user discovery or search.
7. THE use case surface SHALL include `FollowUser`, `UnfollowUser`, and `GetFeed`, plus any additional profile or search use cases needed to complete the feature.
8. FOR ALL valid `ActivityItem` instances, serializing to and deserializing from JSON SHALL produce an equivalent entity.

---

### Requirement 2: Verified-Email Gating

**User Story:** As the app, I want social features gated behind verified email for email-password users, so that low-trust accounts cannot immediately pollute the feed or relationship graph.

#### Acceptance Criteria

1. THE social feature SHALL respect the verified-email gating described in [docs/SECURITY.md](../../../docs/SECURITY.md) and [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md).
2. WHEN an authenticated user has `emailVerified == false`, THE app SHALL prevent access to social-gated routes and interactions.
3. Google and Apple-authenticated users SHALL be treated as verified in line with the existing auth rules.
4. THE social feature SHALL not implement a separate verification model that conflicts with the auth feature's `emailVerified` state.

---

### Requirement 3: Follow and Unfollow

**User Story:** As a user, I want to follow interesting people and unfollow them later, so that my feed reflects the people whose activity I care about.

#### Acceptance Criteria

1. THE social feature SHALL allow an authenticated, verified user to follow another eligible user.
2. THE social feature SHALL prevent a user from following themselves.
3. WHEN a follow succeeds, THE feature SHALL create a `follows/{followId}` relationship consistent with the Firestore schema and security rules in [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md) and [docs/SECURITY.md](../../../docs/SECURITY.md).
4. WHEN a follow succeeds, THE follower's and followed user's counters SHALL be updated so profile counts remain consistent.
5. WHEN an unfollow succeeds, THE follow relationship SHALL be removed and the related counters SHALL be decremented safely.
6. THE feature SHALL treat follow and unfollow as idempotent user actions: duplicate follow attempts SHALL not create duplicate relationships, and duplicate unfollow attempts SHALL not corrupt counters.
7. THE follow button UI SHALL reactively reflect the current relationship state.

---

### Requirement 4: Activity Feed

**User Story:** As a user, I want a feed of friend activity, so that MatchLog feels alive and gives me reasons to return.

#### Acceptance Criteria

1. THE social feature SHALL provide a `FeedScreen` showing `ActivityItem` records relevant to the current user.
2. THE feed SHALL be sourced from the Firestore `activity_feed/{activityId}` collection structure documented in [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md).
3. THE feed SHALL treat `activity_feed` as read-only from the client because [docs/SECURITY.md](../../../docs/SECURITY.md) states only Cloud Functions may write to it.
4. THE feed SHALL render activities derived from supported types in the documented `ActivityType` enum such as `matchLogged`, `betPlaced`, `predictionMade`, `betSettled`, `reviewPosted`, `groupJoined`, and `slipVerified`.
5. THE feed SHALL show summary text, actor identity, and created time for each activity item.
6. THE social feature SHALL not require the client to fan out activity writes directly; the client only consumes feed items and controls whether the user's own activity is eligible for feed sharing.
7. WHEN the feed has no visible items, THE screen SHALL render an onboarding-friendly empty state instead of failing.

---

### Requirement 5: User Profiles

**User Story:** As a user, I want to open another person's profile, so that I can inspect who they are, their stats summary, and whether I want to follow them.

#### Acceptance Criteria

1. THE social feature SHALL provide a profile screen for viewing another user's social profile.
2. THE social profile SHALL render at minimum the user's display name, avatar, favorite sport, favorite team when present, follower count, following count, and follow state.
3. THE profile screen SHALL include a recent-activity section or equivalent social context derived from available feed data.
4. THE profile screen SHALL respect privacy settings including `profileVisibility` and `showBettingStats`.
5. WHEN a profile is visible but `showBettingStats == false`, THE UI SHALL suppress betting-stat sections rather than leaking them.
6. THE profile screen SHALL remain compatible with later Truth Score badge additions documented in design, but SHALL not require verification features to ship first.

---

### Requirement 6: Followers, Following, and User Discovery

**User Story:** As a user, I want to browse followers, following, and discover new people, so that the social graph is explorable rather than hidden.

#### Acceptance Criteria

1. THE social feature SHALL provide list screens for followers and following relationships.
2. EACH list entry SHALL show enough user summary data to identify the person and act on the relationship state.
3. THE feature SHALL provide a user-search or discovery screen for finding profiles to follow.
4. THE discovery experience SHALL respect the documented `allowDiscovery` privacy setting in [docs/SECURITY.md](../../../docs/SECURITY.md).
5. THE discovery experience SHALL not expose users who have opted out of discovery unless another access rule explicitly allows it.
6. THE follow and unfollow actions from followers, following, or discovery surfaces SHALL remain consistent with the same relationship source of truth.

---

### Requirement 7: Privacy and Feed-Sharing Controls

**User Story:** As a user, I want control over whether my activity appears in social contexts, so that I can participate without losing privacy.

#### Acceptance Criteria

1. THE social feature SHALL respect the documented privacy settings: `profileVisibility`, `allowDiscovery`, `showBettingStats`, and `shareActivityToFeed`.
2. WHEN `shareActivityToFeed == false`, THE user's client-side actions SHALL not be treated as eligible social activity for feed publication from that point forward.
3. WHEN a profile is private or friends-only, THE social feature SHALL render access-denied or limited-visibility states rather than leaking hidden fields.
4. THE social feature SHALL not broaden access to private betting data beyond the visibility and friendship semantics already established elsewhere in the system.
5. THE social feature SHALL keep feed participation and discovery separate; disabling discovery SHALL not necessarily imply blocking existing followers from seeing already-allowed activity.

---

### Requirement 8: Local Cache and Offline Behavior

**User Story:** As a user on an unreliable connection, I want profile and relationship views to degrade gracefully, so that the app remains usable even when live social data is unavailable.

#### Acceptance Criteria

1. THE social feature SHALL reuse the existing local `Follows` and `UserProfiles` tables where appropriate for relationship and profile caching.
2. THE feature SHALL treat Firestore as the authoritative source for the activity feed, since no Phase 1 local feed table exists.
3. WHEN cached profile or follow data exists, THE feature SHALL prefer showing that data over a blank screen while remote refresh runs.
4. WHEN the activity feed cannot be refreshed due to connectivity issues, THE screen SHALL show a recoverable error or stale-data state instead of crashing.
5. THE feature SHALL not invent a separate, conflicting local profile schema when `UserProfiles` already exists.

---

### Requirement 9: Routing and Riverpod Integration

**User Story:** As a developer, I want the social feature wired into the provider graph and router, so that the social layer behaves consistently with the rest of the app.

#### Acceptance Criteria

1. THE social feature SHALL expose Riverpod providers for the repository, follow state, feed state, profile state, follower or following lists, and discovery results.
2. THE `feedProvider` SHALL expose the current user's activity feed as an `AsyncValue<List<ActivityItem>>`, consistent with [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md).
3. THE feature SHALL derive the active `userId` from the authenticated user provider rather than passing it manually through widgets.
4. THE feature SHALL integrate with GoRouter through routes for feed, profile, followers or following, and user search.
5. THE Social tab in bottom navigation SHALL resolve into this feature's entry surface rather than a placeholder once Phase 2 ships.
6. THE feature SHALL keep Firestore query and relationship mutation logic in providers or repositories, not in widgets.

---

### Requirement 10: Security and Data Ownership

**User Story:** As the app, I want social writes and reads to follow the documented ownership and Cloud Function boundaries, so that clients do not bypass server-side social rules.

#### Acceptance Criteria

1. THE client SHALL only create or delete `follows` documents where the authenticated user is the `followerId`, consistent with [docs/SECURITY.md](../../../docs/SECURITY.md).
2. THE client SHALL never write directly to `activity_feed`, because that collection is Cloud Function-owned.
3. THE social feature SHALL not trust widget-provided user ids over authenticated session state when creating or deleting follow relationships.
4. THE feature SHALL preserve privacy-setting semantics when exposing profile or discovery results.
5. THE feature SHALL remain compatible with account-deletion behavior that removes follows and related user data.

---

### Requirement 11: Testing and Correctness Properties

**User Story:** As a developer, I want strong automated coverage for follows, profile privacy, and feed consumption, so that the social layer does not regress as later features add more activity types.

#### Acceptance Criteria

1. THE test suite SHALL include unit tests for `FollowUser`, `UnfollowUser`, and `GetFeed`.
2. THE test suite SHALL include repository tests covering successful follow, successful unfollow, duplicate follow handling, cached profile reads, and feed reads from Firestore-backed sources.
3. THE test suite SHALL include widget tests for `FeedScreen`, `ProfileScreen`, `FollowersScreen`, and `UserSearchScreen`.
4. THE test suite SHALL include widget tests for `FollowButton`, `ActivityCard`, and `UserAvatar`.
5. FOR ALL valid `ActivityItem` instances, JSON serialization followed by deserialization SHALL return an equivalent entity.
6. FOR ALL follow operations, THE relation graph SHALL never contain duplicate edges for the same `(followerId, followingId)` pair.
7. FOR ALL valid follower and following count transitions, THE displayed counters SHALL remain non-negative.
8. FOR ALL activity types supported by the feed, THE rendering layer SHALL map them to a deterministic visual treatment or safe fallback.
