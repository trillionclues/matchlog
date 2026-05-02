# Requirements Document

## Introduction

Phase 1.5 Extras adds the first post-launch polish layer on top of the shipped solo tracking loop. It groups four closely related capabilities called out in [docs/PROJECT.md](../../../docs/PROJECT.md):

1. stadium check-in
2. push notifications
3. calendar heatmap
4. social share cards

These enhancements deepen habit formation and make MatchLog more expressive without turning the app into a social network yet. They must build on the completed Phase 1 foundations and earlier feature specs rather than duplicating infrastructure.

This composite feature intentionally spans both core and feature-level code:

1. notifications are a core app concern and belong under `lib/core/notifications/`
2. calendar heatmap extends the diary stats experience
3. stadium check-in upgrades diary entries through the existing `geoVerified` field
4. share-card generation aligns with the documented Phase 1.5 `year_review` and shareable-card direction

The feature must preserve the app's offline-first posture where possible, degrade gracefully when permissions are denied, and avoid introducing Phase 2 social-feed behavior prematurely.

---

## Glossary

- **Stadium Check-In**: A location-based flow that verifies a match log was recorded from a stadium context and upgrades `geoVerified` on the related `MatchEntry`.
- **GeoVerified**: The existing `MatchEntry` flag indicating a stadium check-in has been verified.
- **Calendar Heatmap**: The GitHub-style activity visualization showing match-log density over time.
- **NotificationService**: The core service responsible for FCM setup and foreground or background notification handling.
- **NotificationHandler**: The core router bridge that opens the correct screen when a notification is tapped.
- **NotificationQueue**: The core helper for batching or deferring notification work when device conditions require it.
- **Notification Channels**: The Android notification channels defined in architecture docs for reminders, settlements, social activity, digests, and AI insights.
- **Share Card**: A rendered PNG image representing user stats or match moments for external sharing.
- **Share Card Generator**: The renderer that turns a widget tree into an image using `RepaintBoundary.toImage()`.
- **YearReview**: The documented Phase 1.5 aggregate model used to power recap and shareable card surfaces.

---

## Requirements

### Requirement 1: Composite Architecture Alignment

**User Story:** As a developer, I want the Phase 1.5 enhancements structured across the correct layers and modules, so that cross-cutting features like notifications do not end up buried inside unrelated feature folders.

#### Acceptance Criteria

1. THE Phase 1.5 spec SHALL treat notifications as a core concern implemented under `lib/core/notifications/`, consistent with [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md).
2. THE feature SHALL treat calendar heatmap as an extension of diary presentation and stats.
3. THE feature SHALL treat stadium check-in as an enhancement to diary entries using the existing `geoVerified` field on `MatchEntry`.
4. THE feature SHALL treat share-card generation as a presentation-layer capability backed by aggregate user data and the documented `YearReview` model where relevant.
5. THE feature SHALL reuse the existing Phase 1 infrastructure: `AppDatabase`, Riverpod providers, GoRouter, design tokens, and shared widgets.
6. THE feature SHALL not duplicate previously specified diary, betting, auth, or match-search domain models when existing contracts already cover the required data.

---

### Requirement 2: Stadium Check-In

**User Story:** As a user attending a match in person, I want to verify that I was at the stadium, so that my diary reflects real match-going experiences instead of only TV or stream logs.

#### Acceptance Criteria

1. THE Phase 1.5 feature SHALL provide a stadium check-in flow accessible from a relevant diary entry or log-match flow when `watchType == WatchType.stadium`.
2. THE stadium check-in flow SHALL request location permission through the platform permission flow before attempting GPS verification.
3. WHEN location permission is denied or unavailable, THE feature SHALL fail gracefully and SHALL not block the user from keeping the diary entry itself.
4. WHEN the app determines the user is eligible for a verified stadium check-in, THE related `MatchEntry` SHALL be updated with `geoVerified = true`.
5. WHEN a stadium check-in cannot be verified, THE related `MatchEntry` SHALL remain `geoVerified = false`.
6. THE stadium check-in flow SHALL not set `geoVerified = true` for non-stadium watch types.
7. THE UI SHALL present a visible verified badge or equivalent indicator when a diary entry has `geoVerified = true`.

---

### Requirement 3: Calendar Heatmap

**User Story:** As a user, I want to see my match-logging activity across the calendar, so that I can understand streaks, habits, and quiet periods at a glance.

#### Acceptance Criteria

1. THE Phase 1.5 feature SHALL provide a calendar heatmap view derived from the user's diary entries.
2. THE heatmap SHALL use the GitHub-style activity pattern described in [docs/DESIGN.md](../../../docs/DESIGN.md), including day cells with intensity tiers for activity level.
3. THE heatmap SHALL be driven from locally available diary data and SHALL not require a separate network request to render.
4. THE heatmap SHALL support tapping a day cell to inspect the matches logged on that day.
5. THE heatmap SHALL surface current streak information and align it with the diary stats logic rather than computing a conflicting second streak system.
6. THE heatmap SHALL reuse the app's existing color tokens and SHALL follow the documented color scale from low to high activity.
7. WHEN no diary data exists, THE heatmap view SHALL render a meaningful empty state instead of crashing or showing corrupt cells.

---

### Requirement 4: Push Notifications Infrastructure

**User Story:** As a user, I want the app to notify me about relevant moments, so that MatchLog stays useful between manual sessions.

#### Acceptance Criteria

1. THE Phase 1.5 feature SHALL implement core push-notification plumbing using Firebase Cloud Messaging plus local rendering through `flutter_local_notifications`, consistent with [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md).
2. THE app SHALL support foreground and background notification handling through a core `NotificationService`.
3. THE app SHALL route notification taps through a core `NotificationHandler` that can open the correct in-app destination.
4. THE Phase 1.5 notification system SHALL remain compatible with the existing `NotificationType` enum defined in [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md).
5. THE app SHALL create the Android notification channels documented in architecture: `match_reminders`, `bet_settlements`, `social_activity`, `weekly_digest`, and `ai_insights`.
6. THE app SHALL request notification permission where the platform requires it and SHALL degrade gracefully if the user declines.
7. THE feature SHALL not require Gemini-generated notification copy for baseline functionality; AI-personalized copy remains optional within the documented Phase 1.5 direction.

---

### Requirement 5: Notification Preferences

**User Story:** As a user, I want control over which notifications I receive, so that MatchLog stays helpful instead of noisy.

#### Acceptance Criteria

1. THE Phase 1.5 feature SHALL provide a notification settings surface, consistent with the Phase 1.5 screen inventory in [docs/DESIGN.md](../../../docs/DESIGN.md).
2. THE notification settings surface SHALL expose at minimum the preference fields already present in the documented user settings model: `matchReminders`, `betSettlements`, and `socialActivity`.
3. THE app SHALL persist notification preference changes to the user settings structure under `users/{userId}/settings`, consistent with [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md).
4. THE notification system SHALL respect the user's saved settings when determining whether a local or remote notification should be displayed.
5. WHEN notification permissions are disabled at the OS level, THE settings UI SHALL communicate that state clearly rather than pretending delivery is active.

---

### Requirement 6: Share Cards

**User Story:** As a user, I want visually strong shareable cards for my MatchLog stats and moments, so that I can post them externally to Instagram, WhatsApp, or X.

#### Acceptance Criteria

1. THE Phase 1.5 feature SHALL provide social share-card generation as a share-sheet flow rather than an in-app social feed post.
2. THE share-card generator SHALL render cards to PNG via `RepaintBoundary.toImage()`, consistent with [docs/DESIGN.md](../../../docs/DESIGN.md).
3. THE generator SHALL support at least the documented card aspect directions: portrait, square, and landscape.
4. THE shared card content SHALL be backed by real app data rather than freeform user text only.
5. THE feature SHALL support at least one recap-style template and one lightweight stat-sharing template.
6. THE app SHALL use the platform share sheet to share generated card images externally.
7. THE Phase 1.5 share-card flow SHALL not require posting to an internal activity feed, since that belongs to later social features.

---

### Requirement 7: Recap and Year-Review Compatibility

**User Story:** As a developer, I want Phase 1.5 share cards to align with the documented year-review direction, so that the share infrastructure does not need a full rewrite later.

#### Acceptance Criteria

1. THE Phase 1.5 feature SHALL remain compatible with the documented `YearReview` aggregate model in [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md).
2. THE share-card system SHALL be able to consume aggregate recap data such as total matches, ROI, top team, top league, stadium visits, and streaks.
3. THE Phase 1.5 scope MAY ship shareable recap cards before a full multi-slide wrapped flow is complete, but the rendering contract SHALL not block the later `year_review` screen direction documented in architecture.
4. THE share-card generator SHALL be designed as reusable infrastructure rather than hardcoded to a single static template.

---

### Requirement 8: Routing and Riverpod Integration

**User Story:** As a developer, I want Phase 1.5 extras wired into the existing provider graph and router, so that the new screens and services behave like part of the app instead of side systems.

#### Acceptance Criteria

1. THE Phase 1.5 feature SHALL expose Riverpod providers for notification service state, notification preference state, stadium check-in actions, heatmap data, and share-card generation state as appropriate.
2. THE heatmap view SHALL consume diary-derived data through providers rather than querying storage directly inside widgets.
3. THE stadium check-in flow SHALL operate on the current user's diary entry context derived from existing auth and diary providers.
4. THE notification system SHALL integrate with GoRouter navigation through a dedicated handler rather than embedding route logic inside raw Firebase callbacks.
5. THE feature SHALL add or wire routes for notification settings, calendar heatmap, stadium check-in, and share preview where needed.
6. THE feature SHALL remain compatible with the existing bottom navigation and not create a separate navigation shell.

---

### Requirement 9: Privacy, Permissions, and Data Handling

**User Story:** As a user, I want Phase 1.5 enhancements to respect my privacy and permissions, so that location, notifications, and sharing stay under my control.

#### Acceptance Criteria

1. THE stadium check-in flow SHALL request location only when the user explicitly initiates that action.
2. THE app SHALL not turn on location verification silently in the background.
3. THE notification system SHALL request notification permission explicitly and handle denial gracefully.
4. THE share-card flow SHALL only export data the user can already see in-app.
5. THE feature SHALL not require uploading generated share cards to backend storage unless a later feature explicitly adds that requirement.
6. THE feature SHALL respect account-deletion expectations by ensuring any persisted settings or local artifacts remain compatible with the existing user-data deletion model.

---

### Requirement 10: Testing and Correctness Properties

**User Story:** As a developer, I want strong automated coverage for the new polish-layer features, so that visualizations, permission flows, and notification routing do not regress.

#### Acceptance Criteria

1. THE test suite SHALL include widget tests for the calendar heatmap view and its day-selection behavior.
2. THE test suite SHALL include unit or widget tests for notification channel registration and notification preference handling.
3. THE test suite SHALL include tests for stadium check-in behavior covering successful verification, denied permission, and non-stadium-entry rejection.
4. THE test suite SHALL include tests for share-card generation and share-preview rendering.
5. FOR ALL diary-entry datasets rendered into the heatmap, THE sum of day-cell counts across the selected range SHALL equal the number of entries included in that range.
6. FOR ALL diary-entry datasets, THE displayed current streak SHALL be less than or equal to the displayed longest streak.
7. FOR ALL share-card render requests with supported templates and aspect ratios, THE generator SHALL produce a non-empty image output with the requested layout dimensions.
8. FOR ALL notification types supported in Phase 1.5, THE notification routing layer SHALL map them to a deterministic in-app destination or safe no-op behavior.
