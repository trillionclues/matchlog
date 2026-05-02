# Implementation Tasks: Social

## Tasks

- [ ] 1. Spec and dependency alignment
  - [ ] 1.1 Treat `.kiro/specs/social/` as the canonical implementation spec for the social feature
  - [ ] 1.2 Reuse existing Phase 1 and 1.5 assets (`UserProfiles`, `Follows`, auth verification state, routes, notification preference hooks, and design tokens) instead of creating duplicate social infrastructure
  - [ ] 1.3 Keep activity-feed writes server-owned and do not implement client-side writes to `activity_feed`

- [ ] 2. Social domain layer
  - [ ] 2.1 Implement `lib/features/social/domain/entities/user_profile.dart`
  - [ ] 2.2 Implement `lib/features/social/domain/entities/follow_relationship.dart`
  - [ ] 2.3 Implement `lib/features/social/domain/entities/activity_item.dart`
  - [ ] 2.4 Implement `lib/features/social/domain/failures/social_failure.dart`
  - [ ] 2.5 Implement `lib/features/social/domain/repositories/social_repository.dart`
  - [ ] 2.6 Implement use cases for `follow_user`, `unfollow_user`, and `get_feed`

- [ ] 3. Firebase data source
  - [ ] 3.1 Implement `lib/features/social/data/social_firebase_source.dart`
  - [ ] 3.2 Implement Firestore reads and writes for follows within documented ownership constraints
  - [ ] 3.3 Implement read-only activity-feed queries and mapping
  - [ ] 3.4 Implement profile, settings, follower, following, and discoverable-user reads
  - [ ] 3.5 Respect `allowDiscovery`, `profileVisibility`, and `showBettingStats` when building read models

- [ ] 4. Repository and local cache orchestration
  - [ ] 4.1 Implement `lib/features/social/data/social_repository_impl.dart`
  - [ ] 4.2 Reuse local `UserProfiles` and `Follows` tables for relationship and profile caching where appropriate
  - [ ] 4.3 Implement verified-email gating before social mutations and protected reads
  - [ ] 4.4 Prevent self-follow and duplicate-follow edges
  - [ ] 4.5 Keep follower and following counters non-negative and internally consistent

- [ ] 5. Feed experience
  - [ ] 5.1 Implement `lib/features/social/presentation/screens/feed_screen.dart`
  - [ ] 5.2 Implement `lib/features/social/presentation/widgets/activity_card.dart`
  - [ ] 5.3 Render supported activity types with deterministic UI mapping
  - [ ] 5.4 Add onboarding-friendly empty-state behavior when no visible activity exists

- [ ] 6. Profiles and relationship views
  - [ ] 6.1 Implement `lib/features/social/presentation/screens/profile_screen.dart`
  - [ ] 6.2 Implement `lib/features/social/presentation/screens/followers_screen.dart`
  - [ ] 6.3 Implement `lib/features/social/presentation/screens/user_search_screen.dart`
  - [ ] 6.4 Implement `lib/features/social/presentation/widgets/user_avatar.dart`
  - [ ] 6.5 Implement `lib/features/social/presentation/widgets/follow_button.dart`
  - [ ] 6.6 Ensure profile UI respects privacy settings and suppresses betting stats when configured

- [ ] 7. Riverpod providers and controllers
  - [ ] 7.1 Implement `lib/features/social/presentation/providers/social_providers.dart`
  - [ ] 7.2 Expose `feedProvider`, `userProfileProvider`, follower/following list providers, and user-search providers
  - [ ] 7.3 Add follow and unfollow controller providers with loading and failure state
  - [ ] 7.4 Derive current user and verification state from auth providers instead of passing them through widgets

- [ ] 8. Router integration
  - [ ] 8.1 Wire routes for feed, profile, followers/following, and user search
  - [ ] 8.2 Point the Social bottom-nav tab to the feed entry surface
  - [ ] 8.3 Keep route protection centralized in the existing auth-aware router layer

- [ ] 9. Privacy and compliance refinements
  - [ ] 9.1 Respect `allowDiscovery` in user search and discovery results
  - [ ] 9.2 Respect `shareActivityToFeed` when determining activity eligibility boundaries
  - [ ] 9.3 Respect `profileVisibility` and `showBettingStats` on profile rendering
  - [ ] 9.4 Keep activity-feed publication server-owned via Cloud Functions

- [ ] 10. Testing
  - [ ] 10.1 Add unit tests for `follow_user`, `unfollow_user`, and `get_feed`
  - [ ] 10.2 Add tests for `ActivityItem` JSON round-trip
  - [ ] 10.3 Add repository tests for follow success, unfollow success, duplicate-follow rejection, self-follow rejection, cached profile reads, and feed mapping
  - [ ] 10.4 Add widget tests for `FeedScreen`, `ProfileScreen`, `FollowersScreen`, and `UserSearchScreen`
  - [ ] 10.5 Add widget tests for `FollowButton`, `ActivityCard`, and `UserAvatar`
  - [ ] 10.6 Add property-based tests for duplicate-edge prevention, non-negative counters, and deterministic activity rendering

- [ ] 11. Verification and cleanup
  - [ ] 11.1 Run `dart run build_runner build --delete-conflicting-outputs`
  - [ ] 11.2 Run `flutter test`
  - [ ] 11.3 Run `flutter analyze`
  - [ ] 11.4 Manually verify the core social flow: search user -> follow -> open profile -> view feed -> unfollow
