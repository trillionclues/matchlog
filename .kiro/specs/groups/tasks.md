# Implementation Tasks: Groups

## Tasks

- [ ] 1. Spec and dependency alignment
  - [ ] 1.1 Treat `.kiro/specs/groups/` as the canonical implementation spec for the groups feature
  - [ ] 1.2 Reuse existing Phase 1 and Phase 2 assets (`BookieGroups`, `GroupMembers`, `Predictions`, auth verification state, match-search fixture handoff, routes, and sync queue) instead of creating duplicate infrastructure
  - [ ] 1.3 Keep group pricing and member-cap rules enforced in app logic and supporting backend flows where Firestore rules cannot enforce them directly

- [ ] 2. Groups domain layer
  - [ ] 2.1 Implement `lib/features/groups/domain/entities/bookie_group.dart`
  - [ ] 2.2 Implement `lib/features/groups/domain/entities/group_member.dart`
  - [ ] 2.3 Implement `lib/features/groups/domain/entities/group_prediction.dart`
  - [ ] 2.4 Implement `lib/features/groups/domain/entities/group_invite.dart`
  - [ ] 2.5 Reuse or wire the documented `LeaderboardEntry` model for leaderboard output
  - [ ] 2.6 Implement `lib/features/groups/domain/failures/group_failure.dart`
  - [ ] 2.7 Implement `lib/features/groups/domain/repositories/group_repository.dart`
  - [ ] 2.8 Implement use cases for `create_group`, `join_group`, `submit_prediction`, and `get_leaderboard`

- [ ] 3. Firebase data source
  - [ ] 3.1 Implement `lib/features/groups/data/group_firebase_source.dart`
  - [ ] 3.2 Implement group creation and initial admin membership writes
  - [ ] 3.3 Implement invite-code lookup and membership creation
  - [ ] 3.4 Implement prediction creation and reads
  - [ ] 3.5 Implement leaderboard input reads from member and prediction data

- [ ] 4. Repository and local cache orchestration
  - [ ] 4.1 Implement `lib/features/groups/data/group_repository_impl.dart`
  - [ ] 4.2 Reuse local Drift group tables for offline-first reads and local mutation state
  - [ ] 4.3 Implement verified-email gating before group creation, joining, and prediction submission
  - [ ] 4.4 Enforce Free-tier group-count and 5-member constraints in app logic
  - [ ] 4.5 Prevent duplicate membership and duplicate replay side effects during sync
  - [ ] 4.6 Keep leaderboard ranking deterministic and centralized in repository/use case logic

- [ ] 5. Group creation and joining UX
  - [ ] 5.1 Implement `lib/features/groups/presentation/screens/create_group_screen.dart`
  - [ ] 5.2 Implement `lib/features/groups/presentation/screens/groups_list_screen.dart`
  - [ ] 5.3 Implement invite-code input and join flow
  - [ ] 5.4 Implement deep-link-compatible join handling without duplicating invite business logic
  - [ ] 5.5 Surface tier-limit, invalid-invite, already-member, and group-full states clearly in the UI

- [ ] 6. Group detail and prediction UX
  - [ ] 6.1 Implement `lib/features/groups/presentation/screens/group_detail_screen.dart`
  - [ ] 6.2 Implement `lib/features/groups/presentation/screens/prediction_board.dart`
  - [ ] 6.3 Implement `lib/features/groups/presentation/screens/leaderboard_screen.dart`
  - [ ] 6.4 Implement `lib/features/groups/presentation/widgets/group_card.dart`
  - [ ] 6.5 Implement `lib/features/groups/presentation/widgets/prediction_card.dart`
  - [ ] 6.6 Implement `lib/features/groups/presentation/widgets/leaderboard_row.dart`
  - [ ] 6.7 Implement `lib/features/groups/presentation/widgets/invite_code_card.dart`

- [ ] 7. Prediction rules
  - [ ] 7.1 Prefill predictions from match-search fixture selection when available
  - [ ] 7.2 Enforce kickoff deadline validation before repository writes
  - [ ] 7.3 Keep predictions client-non-deletable after creation
  - [ ] 7.4 Ensure settled prediction outcomes can feed leaderboard stats consistently

- [ ] 8. Riverpod providers and routing
  - [ ] 8.1 Implement `lib/features/groups/presentation/providers/group_providers.dart`
  - [ ] 8.2 Expose `groupsProvider`, group detail providers, prediction providers, and `leaderboardProvider(groupId)`
  - [ ] 8.3 Add create, join, and submit-prediction controller providers with loading and failure state
  - [ ] 8.4 Wire routes for groups list, group detail, create group, prediction board, leaderboard, and join group
  - [ ] 8.5 Derive current user and verification state from auth providers instead of passing them through widgets

- [ ] 9. Security and ownership refinements
  - [ ] 9.1 Restrict admin-only UI actions to group admins
  - [ ] 9.2 Restrict prediction creation to the authenticated user
  - [ ] 9.3 Keep prediction deletion unavailable in client UI
  - [ ] 9.4 Preserve invite-code validation and membership-cap rules in app logic even though some rules are not fully enforceable in Firestore

- [ ] 10. Testing
  - [ ] 10.1 Add unit tests for `create_group`, `join_group`, `submit_prediction`, and `get_leaderboard`
  - [ ] 10.2 Add tests for `LeaderboardEntry` JSON round-trip
  - [ ] 10.3 Add repository tests for creation, invite join, invalid invites, duplicate membership rejection, kickoff deadline enforcement, and leaderboard reads
  - [ ] 10.4 Add widget tests for `GroupsListScreen`, `GroupDetailScreen`, `CreateGroupScreen`, `PredictionBoard`, and `LeaderboardScreen`
  - [ ] 10.5 Add widget tests for `GroupCard`, `PredictionCard`, `LeaderboardRow`, and `InviteCodeCard`
  - [ ] 10.6 Add property-based tests for duplicate-member prevention, kickoff deadline rejection, and deterministic leaderboard ordering

- [ ] 11. Verification and cleanup
  - [ ] 11.1 Run `dart run build_runner build --delete-conflicting-outputs`
  - [ ] 11.2 Run `flutter test`
  - [ ] 11.3 Run `flutter analyze`
  - [ ] 11.4 Manually verify the core groups flow: create group -> invite/join -> submit prediction -> view leaderboard
