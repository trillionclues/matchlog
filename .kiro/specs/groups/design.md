# Design Document: Groups

## Overview

The groups feature is MatchLog's Phase 2 structured multiplayer layer. It adds:

1. Bookie Group creation and membership
2. invite-based joining
3. group predictions
4. leaderboard ranking

This feature sits between the social layer and later verification systems:

- it builds on social identity and verified-email gating
- it reuses match search for fixture selection
- it remains compatible with later Truth Score and prediction-league work without requiring them now

---

## Architecture

### Layering

```text
Presentation  ->  Domain  <-  Data
                   ^          ^
                   |          |
                 Core   Firestore + Drift Groups/Predictions + SyncQueue
```

- `domain/` stays pure Dart and defines group, member, prediction, invite, and leaderboard contracts
- `data/` composes Firestore group structures with existing local Drift tables
- `presentation/` owns list, detail, creation, prediction, and leaderboard screens
- `core/` supplies auth state, routing, sync queue, and shared UI primitives

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
    └── groups/
        ├── data/
        │   ├── group_repository_impl.dart
        │   └── group_firebase_source.dart
        ├── domain/
        │   ├── entities/
        │   │   ├── bookie_group.dart
        │   │   ├── group_invite.dart
        │   │   ├── group_member.dart
        │   │   └── group_prediction.dart
        │   ├── failures/
        │   │   └── group_failure.dart
        │   ├── repositories/
        │   │   └── group_repository.dart
        │   └── usecases/
        │       ├── create_group.dart
        │       ├── get_leaderboard.dart
        │       ├── join_group.dart
        │       └── submit_prediction.dart
        └── presentation/
            ├── providers/
            │   └── group_providers.dart
            ├── screens/
            │   ├── create_group_screen.dart
            │   ├── group_detail_screen.dart
            │   ├── groups_list_screen.dart
            │   ├── leaderboard_screen.dart
            │   └── prediction_board.dart
            └── widgets/
                ├── group_card.dart
                ├── invite_code_card.dart
                ├── leaderboard_row.dart
                └── prediction_card.dart
```

---

## Domain Design

### `BookieGroup`

`BookieGroup` already has a documented canonical shape and should remain the source of truth for group identity:

- `id`
- `name`
- `adminId`
- `privacy`
- `inviteCode`
- `leagueFocus`
- `sportFocus`
- `memberCount`
- `createdAt`

### `GroupMember`

The local and remote schemas imply a small but important member model:

- `groupId`
- `userId`
- `role`
- `totalPredictions`
- `correctPredictions`
- `winRate`
- `joinedAt`

This should stay separate from broader social `UserProfile` so group-specific stats do not leak into unrelated profile code.

### `GroupPrediction`

Predictions should be group-bound and immutable-after-creation from the client perspective.

Important invariants:

- `groupId` is required for group competition
- submission must happen before `kickoffAt`
- once created, predictions are not client-deletable
- settlement is a later/adjacent concern, not a form-time concern

### `LeaderboardEntry`

The documented `LeaderboardEntry` model should be reused directly.

Ranking rule:

- `totalPoints` is the primary ranking metric
- deterministic tie-breaking should be defined at repository level so repeated reads produce stable order

### `GroupFailure`

Useful failure variants include:

- `notVerified`
- `notFound`
- `invalidInvite`
- `groupFull`
- `alreadyMember`
- `forbidden`
- `kickoffPassed`
- `duplicatePrediction`
- `unknown`

Each variant should expose presentation-safe copy.

### Repository Contract

The repository API should look roughly like this:

```dart
abstract interface class GroupRepository {
  Future<Either<GroupFailure, BookieGroup>> createGroup(CreateGroupInput input);
  Future<Either<GroupFailure, BookieGroup>> joinGroup({
    required String currentUserId,
    required String inviteCode,
  });
  Stream<List<BookieGroup>> getGroupsForUser(String userId);
  Future<BookieGroup?> getGroupById(String groupId);
  Stream<List<GroupMember>> getMembers(String groupId);
  Future<Either<GroupFailure, Unit>> submitPrediction(GroupPrediction prediction);
  Stream<List<GroupPrediction>> getPredictions(String groupId);
  Future<List<LeaderboardEntry>> getLeaderboard(String groupId);
}
```

---

## Data Layer Design

### Firestore Structures

Relevant documented remote structures:

- `bookie_groups/{groupId}`
- `bookie_groups/{groupId}/members/{userId}`
- `bookie_groups/{groupId}/predictions/{predId}`

Important constraints:

- group CRUD is admin-owned at the top level
- membership updates are limited to the member or admin
- predictions are create-before-kickoff and client-non-deletable

### Local Cache Strategy

The local Drift schema already includes:

- `BookieGroups`
- `GroupMembers`
- `Predictions`

Phase 2 should reuse them for:

- offline-first group visibility
- membership state
- prediction drafts/results visibility
- leaderboard input data where appropriate

The existing `SyncQueue` should remain the queueing mechanism for deferred group and prediction writes.

### `GroupFirebaseSource`

Responsibilities:

- create group documents and initial admin membership
- find group by invite code
- create membership records
- read group details and member lists
- create prediction records
- read predictions and leaderboard inputs

It should not know about Riverpod or widget concerns.

### `GroupRepositoryImpl`

`GroupRepositoryImpl` composes:

- `GroupFirebaseSource`
- local Drift group tables
- auth-derived current-user and verification state
- sync queue behavior from core providers

#### Create Path

```text
CreateGroupScreen submit
  -> CreateGroup use case
  -> GroupRepositoryImpl.createGroup
  -> validate tier + required fields
  -> create local group/member state
  -> create remote group + admin membership
  -> sync status updates
```

#### Join Path

```text
Invite code entered or deep link opened
  -> JoinGroup use case
  -> sanitize/normalize code
  -> find group by invite code
  -> validate not already member + member cap + verification gate
  -> create membership
  -> increment memberCount
```

#### Prediction Path

```text
PredictionBoard submit
  -> SubmitPrediction use case
  -> validate membership + kickoff window
  -> create local prediction
  -> create remote prediction
  -> later settlement updates leaderboard stats
```

#### Leaderboard Path

```text
LeaderboardScreen opens
  -> GetLeaderboard use case
  -> read derived member stats / prediction results
  -> map to LeaderboardEntry
  -> sort deterministically
```

The client should consume derived leaderboard output and not perform ad hoc ranking logic inside widgets.

---

## Pricing and Membership Constraints

The product docs explicitly define Free-tier constraints:

- 1 Bookie Group
- 5 members

These are not fully enforceable in Firestore rules, so the repository and supporting backend logic must enforce them explicitly. The UI should surface these limits clearly rather than failing with generic errors.

---

## Invite and Deep-Link Design

Invite codes are a first-class group entry mechanism.

Rules:

- codes are 6-character uppercase alphanumeric
- invalid format should fail before remote lookup
- join flow should be callable from both manual input and future deep-link handlers

The groups feature should expose a stable invite contract now so later deep-link work only needs to route into it.

---

## Presentation Design

### `GroupsListScreen`

This is the user's entry point into group play.

Layout:

- app bar with create-group entry point
- scrollable list of `GroupCard`
- empty state for users with no groups yet

Each card should show:

- group name
- privacy
- member count
- sport/league focus when present

### `CreateGroupScreen`

The creation form should collect:

- group name
- privacy
- optional sport focus
- optional league focus

Validation should happen before any repository call.

### `GroupDetailScreen`

The group detail surface should show:

- group identity header
- invite code access for eligible users
- members tab
- predictions tab
- leaderboard tab

The admin should have clearly visible admin-only controls where relevant.

### `PredictionBoard`

The prediction board should let members:

- choose or confirm a fixture
- enter prediction text
- select confidence
- see kickoff deadline context

It should support match-search handoff instead of duplicating fixture search.

### `LeaderboardScreen`

The leaderboard should render ranked `LeaderboardRow` items using:

- rank
- display name
- win rate
- points
- current streak

The current user's row should be highlighted when present, following the design direction already documented.

---

## Provider Design

Expected Riverpod surface:

- `groupRepositoryProvider`
- `createGroupProvider`
- `joinGroupProvider`
- `submitPredictionProvider`
- `groupsProvider`
- `groupDetailProvider(groupId)`
- `groupMembersProvider(groupId)`
- `groupPredictionsProvider(groupId)`
- `leaderboardProvider(groupId)`
- `groupInviteControllerProvider`

Design notes:

- derive current user and verification state from auth providers
- keep kickoff validation in providers/repository, not widgets
- keep leaderboard ranking centralized in repository/use case logic

---

## Routing Integration

Expected route additions or wiring:

- `Routes.groups`
- `Routes.groupDetail`
- `Routes.createGroup`
- `Routes.predictionBoard`
- `Routes.leaderboard`
- `Routes.joinGroup`

The join-group route should support invite-code input and deep-link entry without duplicating business logic.

---

## Testing Strategy

### Unit Tests

- `create_group_test.dart`
- `join_group_test.dart`
- `submit_prediction_test.dart`
- `get_leaderboard_test.dart`

### Repository Tests

- group creation
- invite-code join
- invalid invite rejection
- duplicate-membership rejection
- kickoff deadline enforcement
- deterministic leaderboard ordering

### Widget Tests

- `groups_list_screen_test.dart`
- `group_detail_screen_test.dart`
- `create_group_screen_test.dart`
- `prediction_board_test.dart`
- `leaderboard_screen_test.dart`

### Property-Based Correctness

Properties that should be tested with generated inputs where practical:

1. `LeaderboardEntry` JSON round-trip preserves equality
2. a group never contains duplicate members with the same `userId`
3. predictions at or after kickoff are rejected
4. leaderboard ordering is deterministic for identical inputs
