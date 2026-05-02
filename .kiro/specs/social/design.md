# Design Document: Social

## Overview

The social feature is MatchLog's Phase 2 relationship and feed layer. It adds:

1. follow and unfollow
2. activity feed consumption
3. user profiles
4. followers, following, and user discovery

The feature should amplify the existing solo loops rather than create a disconnected social network. That means:

- the feed is built from existing diary, betting, group, and verification actions
- the client consumes feed items but does not author them directly
- privacy and verified-email gating stay central

---

## Architecture

### Layering

```text
Presentation  ->  Domain  <-  Data
                   ^          ^
                   |          |
                 Core   Firestore + Drift UserProfiles/Follows
```

- `domain/` stays pure Dart and defines social entities, failures, repositories, and use cases
- `data/` composes Firestore social reads and writes with existing local profile and follow caches
- `presentation/` owns feed, profile, follower-list, and discovery screens
- `core/` supplies auth state, router integration, privacy gating, and notification hooks

### File Structure

```text
lib/
├── core/
│   ├── di/
│   │   └── providers.dart
│   └── router/
│       ├── app_router.dart
│       └── routes.dart
│
└── features/
    └── social/
        ├── data/
        │   ├── social_repository_impl.dart
        │   └── social_firebase_source.dart
        ├── domain/
        │   ├── entities/
        │   │   ├── activity_item.dart
        │   │   ├── follow_relationship.dart
        │   │   └── user_profile.dart
        │   ├── failures/
        │   │   └── social_failure.dart
        │   ├── repositories/
        │   │   └── social_repository.dart
        │   └── usecases/
        │       ├── follow_user.dart
        │       ├── get_feed.dart
        │       └── unfollow_user.dart
        └── presentation/
            ├── providers/
            │   └── social_providers.dart
            ├── screens/
            │   ├── feed_screen.dart
            │   ├── followers_screen.dart
            │   ├── profile_screen.dart
            │   └── user_search_screen.dart
            └── widgets/
                ├── activity_card.dart
                ├── follow_button.dart
                └── user_avatar.dart
```

---

## Domain Design

### `UserProfile`

The social-facing profile model should be derived from:

- the existing `UserProfiles` local schema
- user settings privacy fields under `users/{userId}/settings`
- follow-state context relative to the viewer

Recommended fields:

- `userId`
- `displayName`
- `photoUrl`
- `favoriteSport`
- `favoriteTeam`
- `followerCount`
- `followingCount`
- `profileVisibility`
- `allowDiscovery`
- `showBettingStats`
- `canViewProfile`
- `isFollowing`

This keeps privacy resolution explicit instead of scattering it across widgets.

### `FollowRelationship`

`FollowRelationship` is a simple domain entity around the existing follows schema:

- `followerId`
- `followingId`
- `createdAt`

It should stay pure and small because the interesting behavior lives in repository and privacy rules.

### `ActivityItem`

`ActivityItem` already has a documented shape and should remain the canonical feed entity.

Feed rendering should derive its iconography and copy treatment from `ActivityType`, not from custom string parsing in widgets.

### `SocialFailure`

Useful failure variants include:

- `notVerified`
- `permission`
- `privateProfile`
- `notFound`
- `network`
- `duplicateFollow`
- `unknown`

Each variant should expose presentation-safe copy.

### Repository Contract

The repository API should look roughly like this:

```dart
abstract interface class SocialRepository {
  Future<Either<SocialFailure, Unit>> followUser({
    required String currentUserId,
    required String targetUserId,
  });
  Future<Either<SocialFailure, Unit>> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  });
  Stream<List<ActivityItem>> getFeed({required String currentUserId});
  Future<UserProfile?> getUserProfile({
    required String currentUserId,
    required String targetUserId,
  });
  Future<List<UserProfile>> getFollowers(String userId);
  Future<List<UserProfile>> getFollowing(String userId);
  Future<List<UserProfile>> searchUsers({
    required String query,
    required String currentUserId,
  });
}
```

---

## Data Layer Design

### Firestore Structures

Relevant documented remote structures:

- `follows/{followId}`
- `activity_feed/{activityId}`
- `users/{userId}` plus settings documents

Important constraints:

- follows are client-authored within ownership rules
- activity feed is client-read-only and Cloud Function-written
- privacy settings affect profile and discovery visibility

### Local Cache Strategy

The existing Drift tables already provide:

- `Follows`
- `UserProfiles`

Phase 2 should reuse them for:

- current relationship state
- cached profile summaries
- follower and following counters

There is no documented local `activity_feed` table in foundation, so the feed should remain Firestore-authoritative for now. If stale data needs to be shown, it should be done through provider state or a later explicit cache schema, not an undocumented implicit cache layer.

### `SocialFirebaseSource`

Responsibilities:

- create and delete follow relationships in Firestore
- read user profile documents and settings
- read followers and following lists
- query or stream activity feed items
- query discoverable user profiles for search

It should not know about Riverpod or widget concerns.

### `SocialRepositoryImpl`

`SocialRepositoryImpl` composes:

- `SocialFirebaseSource`
- local `UserProfiles` and `Follows` access through `AppDatabase`
- auth-derived current-user state

#### Follow Path

```text
Follow button tapped
  -> FollowUser use case
  -> SocialRepositoryImpl.followUser
  -> validate not self + verified email + visibility constraints
  -> create remote follows document
  -> update local follow cache and counters
  -> emit updated follow state
```

#### Unfollow Path

```text
Unfollow tapped
  -> UnfollowUser use case
  -> SocialRepositoryImpl.unfollowUser
  -> delete remote follows document
  -> update local follow cache and counters
  -> emit updated follow state
```

#### Feed Path

```text
FeedScreen opens
  -> getFeed(currentUserId)
  -> stream/read Firestore activity_feed items
  -> map to ActivityItem
  -> render activity cards
```

Because the feed is Cloud Function-owned, the client must not try to write feed rows itself. Separate features can emit user actions, but the feed fan-out remains server-side.

#### Profile Path

```text
ProfileScreen opens
  -> getUserProfile(currentUserId, targetUserId)
  -> read remote profile + privacy settings
  -> merge local cache where available
  -> compute canViewProfile / stat visibility
  -> return UserProfile
```

---

## Privacy and Gating Design

### Verified Email

The auth and security docs are explicit: social routes and actions are gated for unverified email-password users.

Implementation rule:

- deny follow, feed, and profile interactions before making remote calls when `emailVerified == false`
- let the existing router redirect handle route-level protection

### Profile Privacy

The social feature must respect:

- `profileVisibility`
- `allowDiscovery`
- `showBettingStats`
- `shareActivityToFeed`

Design decisions:

- `allowDiscovery` controls search visibility
- `profileVisibility` controls profile access shape
- `showBettingStats` hides betting sections even when profile access is allowed
- `shareActivityToFeed` is a publication eligibility flag, not a feed read permission

### Counter Integrity

Follower and following counts should be treated as eventually consistent but never obviously broken. The repository should guard against negative counts and duplicate follow edges.

---

## Presentation Design

### `FeedScreen`

The feed is the Social tab entry point in Phase 2.

Layout:

- top app bar with feed title
- scrollable list of `ActivityCard`
- empty state encouraging the user to follow people

Each activity card should show:

- user avatar
- display name
- activity summary
- relative timestamp

The visual density should feel like an extension of the existing diary and betting cards, not a separate visual product.

### `ProfileScreen`

The other-user profile should show:

- avatar and display name
- follow button
- favorite sport and team when present
- follower and following counts
- privacy-respecting stats summary
- recent social activity

It should remain compatible with later Truth Score badge placement from design docs, but that badge is not required to launch this feature.

### `FollowersScreen`

This screen can be parameterized for followers or following. Each row should show:

- avatar
- display name
- optional sport affinity info
- follow or unfollow action where applicable

### `UserSearchScreen`

This is the discovery surface for finding people to follow.

Behavior:

- search by display name or discoverable user metadata
- filter out undiscoverable users
- exclude the current user
- show current follow state inline

### `FollowButton`

The follow button should handle:

- loading state
- already-following state
- gated or private-state feedback

It must not optimistically drift into impossible states such as "Following" when the repository call failed.

---

## Provider Design

Expected Riverpod surface:

- `socialRepositoryProvider`
- `followUserProvider`
- `unfollowUserProvider`
- `getFeedProvider`
- `feedProvider`
- `userProfileProvider(userId)`
- `followersProvider(userId)`
- `followingProvider(userId)`
- `userSearchProvider(query)`
- `followControllerProvider(targetUserId)`

Design notes:

- derive current user from auth providers
- centralize profile privacy resolution in providers/repository, not widgets
- expose follow state reactively so profile and list surfaces stay consistent

---

## Routing Integration

Expected route additions or wiring:

- `Routes.feed`
- `Routes.profile`
- `Routes.followers`
- `Routes.userSearch`

If follower/following list variants share one screen, they can use route params or typed extras rather than separate duplicate screens.

The Social bottom-nav tab should route into `FeedScreen` once this feature ships.

---

## Testing Strategy

### Unit Tests

- `follow_user_test.dart`
- `unfollow_user_test.dart`
- `get_feed_test.dart`
- `activity_item_test.dart`

### Repository Tests

- follow success
- unfollow success
- duplicate follow protection
- self-follow rejection
- cached profile merge
- feed read mapping from Firestore payloads

### Widget Tests

- `feed_screen_test.dart`
- `profile_screen_test.dart`
- `followers_screen_test.dart`
- `user_search_screen_test.dart`
- `widgets/follow_button_test.dart`

### Property-Based Correctness

Properties that should be tested with generated inputs where practical:

1. `ActivityItem` JSON round-trip preserves equality
2. follow graph never contains duplicate `(followerId, followingId)` edges
3. follower and following counts never go negative
4. every supported activity type maps to deterministic rendering or safe fallback
