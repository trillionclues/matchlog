# Requirements Document

## Introduction

The Groups feature adds MatchLog's Phase 2 Bookie Groups layer: users create or join private or open groups, submit match predictions, and compete on a leaderboard. This is the first structured multiplayer feature in the app and extends the social layer into recurring shared play.

This feature builds on prior work already specified:

1. auth and social already provide verified-email gating and follow-aware user identity
2. match search already provides typed fixture context for prediction selection
3. the local schema already includes `BookieGroups`, `GroupMembers`, and `Predictions`
4. Firestore security rules already define ownership rules for groups, members, and predictions
5. the project pricing model already defines Free-tier limits around group count and member cap

The Phase 2 scope here is Bookie Groups, predictions, and leaderboard behavior only. Prediction leagues, Truth Score integrations, and monetization-specific upgrades remain outside this spec unless explicitly required by the current Phase 2 docs.

---

## Glossary

- **BookieGroup**: The domain entity representing a prediction group with name, admin, privacy, invite code, and optional league or sport focus.
- **GroupMember**: The domain entity representing one member of a group and their leaderboard stats.
- **GroupPrediction**: The domain entity representing one submitted prediction inside a group context.
- **LeaderboardEntry**: The ranked aggregate model defined in [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md) with rank, points, win rate, and streak.
- **GroupInvite**: The typed representation of an invite-code-based entry path into a group.
- **GroupRepository**: The abstract domain contract for group lifecycle, membership, predictions, and leaderboard reads.
- **GroupRepositoryImpl**: The data-layer implementation that composes local Drift tables with Firestore group structures.
- **GroupsListScreen**: The screen listing groups the current user belongs to or can act on.
- **GroupDetailScreen**: The main group screen showing members, predictions, and leaderboard tabs.
- **PredictionBoard**: The screen or tab used to submit and review group predictions.
- **LeaderboardScreen**: The ranked member list for a group.

---

## Requirements

### Requirement 1: Domain Layer Contracts

**User Story:** As a developer, I want clear group, membership, prediction, and leaderboard entities plus repository contracts, so that the feature remains testable and backend-agnostic.

#### Acceptance Criteria

1. THE groups domain SHALL define a pure Dart `BookieGroup` entity matching [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md): `id`, `name`, `adminId`, `privacy`, `inviteCode`, `leagueFocus`, `sportFocus`, `memberCount`, and `createdAt`.
2. THE groups domain SHALL define a pure Dart `GroupMember` entity with `groupId`, `userId`, `role`, `totalPredictions`, `correctPredictions`, `winRate`, and `joinedAt`.
3. THE groups domain SHALL define a pure Dart `GroupPrediction` entity consistent with the documented predictions schema: `id`, `userId`, `groupId`, `fixtureId`, `matchDescription`, `prediction`, `confidence`, `settled`, `correct`, `points`, `kickoffAt`, and `createdAt`.
4. THE groups domain SHALL reuse the documented `LeaderboardEntry` model for ranked group output.
5. THE groups domain SHALL define a feature-scoped failure type that presentation code can render without inspecting Firebase or Drift exceptions directly.
6. THE `GroupRepository` interface SHALL declare operations for creating groups, joining by invite code, getting groups for a user, getting group details, submitting predictions, getting predictions, and getting the leaderboard.
7. THE use case surface SHALL include `CreateGroup`, `JoinGroup`, `SubmitPrediction`, and `GetLeaderboard`.
8. FOR ALL valid `LeaderboardEntry` instances, serializing to and deserializing from JSON SHALL produce an equivalent entity.

---

### Requirement 2: Verified-Email Gating

**User Story:** As the app, I want group creation, joining, and prediction submission gated behind verified email for email-password users, so that throwaway accounts do not pollute shared competitions.

#### Acceptance Criteria

1. THE groups feature SHALL respect the verified-email gating described in [docs/SECURITY.md](../../../docs/SECURITY.md) and [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md).
2. WHEN an authenticated user has `emailVerified == false`, THE app SHALL prevent group creation, group joining, and prediction submission.
3. THE groups feature SHALL not implement a separate verification model that conflicts with auth's `emailVerified` state.

---

### Requirement 3: Group Creation

**User Story:** As a user, I want to create a Bookie Group with a clear focus and invite path, so that I can compete with friends in a shared context.

#### Acceptance Criteria

1. THE groups feature SHALL allow an authenticated, verified user to create a `BookieGroup`.
2. THE create-group flow SHALL collect at minimum: group `name`, `privacy`, and optional `leagueFocus` or `sportFocus`.
3. WHEN a group is created, THE feature SHALL generate a unique 6-character alphanumeric `inviteCode`, consistent with [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md) and [docs/SECURITY.md](../../../docs/SECURITY.md).
4. WHEN a group is created, THE creator SHALL become the initial `GroupMember` with role `admin`.
5. WHEN a group is created, THE group's initial `memberCount` SHALL be `1`.
6. THE feature SHALL enforce the documented Free-tier rule that a Free user can create at most 1 Bookie Group, with stricter tier expansion left to pricing and subscription work.
7. THE create-group flow SHALL prevent creation when required fields are invalid or missing before any repository call is made.

---

### Requirement 4: Joining Groups by Invite Code

**User Story:** As a user, I want to join a group using an invite code or invite link, so that groups can spread easily through chats and friend circles.

#### Acceptance Criteria

1. THE groups feature SHALL allow an authenticated, verified user to join a group via invite code.
2. THE invite-code flow SHALL sanitize and validate codes against the documented 6-character uppercase alphanumeric format from [docs/SECURITY.md](../../../docs/SECURITY.md).
3. IF the invite code format is invalid, THEN THE feature SHALL fail early with a user-safe validation error before making a repository lookup.
4. IF no group exists for a valid invite code, THEN THE feature SHALL return a user-safe not-found state.
5. THE feature SHALL prevent a user from joining a group they are already a member of.
6. THE feature SHALL enforce the documented Free-tier 5-member limit for free groups or free-cap membership paths where applicable.
7. WHEN a join succeeds, THE feature SHALL create the `GroupMember` relationship and increment `memberCount` safely.
8. THE groups feature SHALL support a join flow that can be opened from a deep-link or typed invite-handling path later without changing the invite contract.

---

### Requirement 5: Group Membership and Detail View

**User Story:** As a group member, I want to open a group and see its members, predictions, and leaderboard context, so that the group feels like an active shared space.

#### Acceptance Criteria

1. THE groups feature SHALL provide a group detail surface for a specific `BookieGroup`.
2. THE group detail view SHALL show at minimum the group name, privacy, member count, invite code access pattern for eligible users, and members.
3. THE group detail view SHALL expose tabs or equivalent sections for members, predictions, and leaderboard, consistent with [docs/DESIGN.md](../../../docs/DESIGN.md).
4. THE feature SHALL distinguish admin and member roles in the group context.
5. THE feature SHALL only allow admin-owned group update or destructive actions in line with the documented Firestore security model.
6. THE groups list surface SHALL let a user browse the groups they belong to without requiring repeated deep links or manual invite re-entry.

---

### Requirement 6: Prediction Submission

**User Story:** As a group member, I want to submit a prediction for an upcoming fixture, so that I can compete on accuracy and points with the rest of the group.

#### Acceptance Criteria

1. THE groups feature SHALL provide a prediction board or equivalent prediction-submission surface for group members.
2. THE prediction submission flow SHALL collect at minimum: fixture context, prediction text, and confidence level.
3. THE feature SHALL store submitted predictions in the documented predictions schema, including `groupId`, `fixtureId`, `matchDescription`, `prediction`, `confidence`, `kickoffAt`, and `createdAt`.
4. THE feature SHALL enforce the documented rule that predictions may only be created before kickoff, consistent with [docs/SECURITY.md](../../../docs/SECURITY.md).
5. IF the current time is at or after `kickoffAt`, THEN THE feature SHALL reject prediction submission before any remote write is attempted.
6. ONCE created, predictions SHALL be treated as permanent from the client perspective and SHALL not be deleted, consistent with the documented security rule.
7. THE prediction flow SHALL support being prefilled from match-search fixture selection without duplicating search logic in the groups feature.

---

### Requirement 7: Prediction Settlement and Leaderboard Stats

**User Story:** As a group member, I want leaderboard stats to reflect prediction outcomes, so that competition feels fair and meaningful.

#### Acceptance Criteria

1. THE groups feature SHALL expose leaderboard output using the documented `LeaderboardEntry` model.
2. THE leaderboard SHALL rank members using `totalPoints` as the primary competition metric.
3. THE leaderboard SHALL show each member's `totalPredictions`, `correctPredictions`, `winRate`, `totalPoints`, and `currentStreak`.
4. WHEN predictions are settled elsewhere in the system, THE related group-member stats and leaderboard output SHALL update consistently.
5. THE groups feature SHALL treat leaderboard reads as derived data and SHALL not require the client to manually recalculate every member's history inside widgets.
6. THE leaderboard screen SHALL highlight the current user's position when present, consistent with the design direction in [docs/DESIGN.md](../../../docs/DESIGN.md).

---

### Requirement 8: Local Cache and Offline Behavior

**User Story:** As a user on an unreliable connection, I want my groups and predictions to degrade gracefully, so that the feature remains usable when connectivity is poor.

#### Acceptance Criteria

1. THE groups feature SHALL reuse the existing local Drift tables `BookieGroups`, `GroupMembers`, and `Predictions` where appropriate for offline-first behavior and local reads.
2. THE feature SHALL write group and prediction mutations locally before or alongside remote sync behavior, consistent with the broader offline-first architecture.
3. WHEN the device is offline, THE feature SHALL allow local group and prediction state to remain visible instead of blanking the screens.
4. WHEN remote sync for group or prediction mutations cannot complete immediately, THE feature SHALL remain compatible with the existing `SyncQueue` infrastructure rather than inventing a parallel queue.
5. THE feature SHALL keep local and remote membership state deterministic enough that duplicate members or duplicate predictions are not introduced by replay behavior.

---

### Requirement 9: Routing and Riverpod Integration

**User Story:** As a developer, I want the groups feature wired into the provider graph and router, so that group flows behave consistently with the rest of the app.

#### Acceptance Criteria

1. THE groups feature SHALL expose Riverpod providers for groups list state, selected group detail state, members state, prediction state, invite-join state, and leaderboard state.
2. THE `groupsProvider` SHALL expose the current user's groups as an `AsyncValue<List<BookieGroup>>`, consistent with [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md).
3. THE `leaderboardProvider(groupId)` SHALL expose a group's leaderboard as an `AsyncValue<List<LeaderboardEntry>>`, consistent with [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md).
4. THE groups feature SHALL derive the active `userId` from auth providers rather than passing it manually through widgets.
5. THE feature SHALL integrate with GoRouter through routes for groups list, group detail, create group, prediction board, leaderboard, and join-group invite handling.
6. THE feature SHALL remain compatible with the existing deep-link and invite-code direction documented in core routing and security docs.

---

### Requirement 10: Security and Ownership Rules

**User Story:** As the app, I want group writes and reads to respect the documented admin, member, and ownership boundaries, so that clients cannot bypass server-side group rules.

#### Acceptance Criteria

1. THE client SHALL only create or delete membership rows that the authenticated user is permitted to create or remove under [docs/SECURITY.md](../../../docs/SECURITY.md).
2. THE client SHALL only allow group updates or deletion flows for the group admin.
3. THE client SHALL only allow prediction creation for the authenticated user, consistent with the documented security rule.
4. THE client SHALL not expose prediction deletion flows because predictions are permanent from the client perspective.
5. THE feature SHALL preserve invite-code validation and membership-limit checks in app logic even though some tier gates are not enforceable in Firestore rules alone.

---

### Requirement 11: Testing and Correctness Properties

**User Story:** As a developer, I want strong automated coverage for creation, joining, predictions, and leaderboard behavior, so that group competition remains fair and stable.

#### Acceptance Criteria

1. THE test suite SHALL include unit tests for `CreateGroup`, `JoinGroup`, `SubmitPrediction`, and `GetLeaderboard`.
2. THE test suite SHALL include repository tests covering group creation, invite join success, invalid invite handling, duplicate-membership rejection, prediction submission before kickoff, and leaderboard reads.
3. THE test suite SHALL include widget tests for `GroupsListScreen`, `GroupDetailScreen`, `CreateGroupScreen`, `PredictionBoard`, and `LeaderboardScreen`.
4. THE test suite SHALL include widget tests for `GroupCard`, `PredictionCard`, `LeaderboardRow`, and `InviteCodeCard`.
5. FOR ALL valid `LeaderboardEntry` instances, JSON serialization followed by deserialization SHALL return an equivalent entity.
6. FOR ALL groups, THE set of members SHALL not contain duplicate `userId` values within the same `groupId`.
7. FOR ALL predictions, submissions at or after kickoff SHALL be rejected while submissions before kickoff remain eligible.
8. FOR ALL leaderboard outputs, ranks SHALL be deterministic for the same input dataset and `totalPoints` ordering.
