# Design Document: Phase 1.5 Extras

## Overview

Phase 1.5 Extras is a coordinated enhancement layer rather than one isolated module. It combines:

1. stadium check-in
2. push notifications and notification settings
3. calendar heatmap
4. share-card generation

These capabilities sit at different places in the architecture:

- notifications belong in `core/notifications/`
- check-in and heatmap extend the diary experience
- share-card generation aligns with the documented `year_review` architecture and share-preview direction

The design goal is to deepen engagement without pulling Phase 2 social feed, groups, or verification behavior into the app prematurely.

---

## Architecture

### Layering

```text
Presentation  ->  Domain  <-  Data / Platform Services
                   ^          ^
                   |          |
                 Core   Geolocator + FCM + Local Notifications + Share
```

- `core/notifications/` owns cross-app notification setup and routing
- `features/diary/` consumes heatmap and check-in enhancements
- `features/year_review/` or equivalent recap/share infrastructure owns reusable share-card data and rendering
- shared providers and router glue everything together

### File Structure

```text
lib/
├── core/
│   ├── notifications/
│   │   ├── channels.dart
│   │   ├── notification_handler.dart
│   │   ├── notification_queue.dart
│   │   └── notification_service.dart
│   ├── di/
│   │   └── providers.dart
│   └── router/
│       ├── app_router.dart
│       └── routes.dart
│
├── features/
│   ├── diary/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── stadium_check_in_screen.dart
│   │       └── widgets/
│   │           └── calendar_heatmap.dart
│   │
│   └── year_review/
│       ├── data/
│       │   └── review_generator.dart
│       ├── domain/
│       │   └── entities/
│       │       └── year_review.dart
│       └── presentation/
│           ├── screens/
│           │   ├── share_preview_screen.dart
│           │   └── year_review_screen.dart
│           └── widgets/
│               ├── review_slide.dart
│               ├── share_card_generator.dart
│               └── stat_card.dart
│
└── shared/
    └── widgets/
        ├── empty_state.dart
        ├── error_state.dart
        └── loading_shimmer.dart
```

The exact filenames can adapt to the current codebase, but the responsibilities should remain split this way.

---

## Stadium Check-In Design

### Data Flow

The feature reuses the existing `MatchEntry.geoVerified` field. No new diary schema is required for the basic verified/unverified outcome.

Flow:

```text
User opens eligible diary entry
  -> taps Check In
  -> app requests location permission
  -> app reads current position
  -> check-in logic validates eligibility
  -> on success: update MatchEntry.geoVerified = true
  -> diary detail/feed reflect verified badge
```

### Eligibility Rules

Minimum Phase 1.5 constraints:

- only diary entries with `watchType == WatchType.stadium` may attempt check-in
- permission denial is a supported, non-fatal outcome
- failed verification never mutates `geoVerified` to true

The docs do not define a stadium-coordinate database, so the Phase 1.5 implementation should avoid pretending to perform more precise verification than the available data supports. A pragmatic approach is:

- use fixture venue context when available
- require explicit user action
- keep the verification rule conservative

### UI

`StadiumCheckInScreen` or an equivalent flow should show:

- current diary entry summary
- permission or GPS status
- verification progress state
- success or failure explanation

The verified outcome should surface back into diary UI as a badge or chip rather than as a hidden field.

---

## Calendar Heatmap Design

### Data Source

The heatmap should be derived entirely from diary entries already available locally.

Recommended transformation:

```text
List<MatchEntry>
  -> group by local calendar date
  -> count entries per day
  -> map count to intensity bucket
  -> compute current streak / longest streak from same dataset
```

This avoids a second analytics store and keeps the heatmap offline-capable.

### Rendering

The design docs specify a `CustomPainter` implementation with rounded cells and intensity tiers:

- no activity -> `surfaceBorder`
- low activity -> `secondary` at lower opacity
- medium activity -> stronger `secondary`
- high activity -> strongest `secondary`

Interactions:

- tap on a cell -> show matches from that day
- streak summary visible near the heatmap

### Consistency Rule

The heatmap and diary stats must not compute independent streak logic. Both should rely on the same aggregation rules so the user never sees contradictory streak numbers.

---

## Notification Design

### Core Services

The architecture already reserves these core components:

- `notification_service.dart`
- `notification_handler.dart`
- `notification_queue.dart`
- `channels.dart`

Responsibilities:

- `NotificationService` initializes FCM and local notifications
- `channels.dart` defines Android channels
- `NotificationHandler` maps tapped notifications into routes
- `NotificationQueue` handles device-state or batching edge cases as needed

### Delivery Flow

```text
Trigger occurs
  -> optional copy generation path
  -> FCM dispatch
  -> device receives push
  -> local notification rendered if needed
  -> user taps notification
  -> NotificationHandler routes to correct screen
```

Baseline triggers for Phase 1.5 should stay within the documented preference model:

- match reminders
- bet settlements
- social activity compatibility hook

### Channel Mapping

The app should create the documented Android channels:

- `match_reminders`
- `bet_settlements`
- `social_activity`
- `weekly_digest`
- `ai_insights`

Even if not every channel is heavily used on day one, defining them now keeps notification behavior stable and consistent.

### Preferences

User notification settings live under the documented `users/{userId}/settings` structure. The Phase 1.5 settings UI should read and write those values through providers or repositories rather than issuing raw widget-level Firestore writes.

---

## Share-Card Design

### Rendering Strategy

The design docs explicitly require share cards to be rendered as PNG from widgets via `RepaintBoundary.toImage()`.

The core pipeline should be:

```text
Aggregate recap/stat data
  -> choose template + aspect ratio
  -> render offscreen/widget preview
  -> capture image bytes
  -> open platform share sheet
```

### Template Direction

At minimum, support:

- portrait template for stories
- square template for feed posts
- landscape template for X/Twitter-like sharing

At minimum, support:

- recap card using year-review style stats
- lighter stat card for single-metric sharing

### Data Sources

The documented `YearReview` aggregate is the cleanest Phase 1.5 compatibility target because it already includes:

- total matches
- total bets
- ROI
- top team
- top league
- stadium visits
- longest streak
- best month / best ROI

The Phase 1.5 implementation does not need to ship every future field to make the share-card infrastructure correct. It only needs a generator that can consume recap-style data now and scale later.

### Preview Flow

Although the design docs list `Share Preview` under Phase 3, the share-card feature benefits from a preview surface even in Phase 1.5. The pragmatic implementation is:

- preview the generated card before invoking `share_plus`
- let the user switch among supported templates or aspect ratios
- keep this as a thin preview, not a full editing studio

---

## Provider Design

Expected Riverpod surface:

- `notificationServiceProvider`
- `notificationPreferencesProvider`
- `notificationPermissionProvider`
- `stadiumCheckInControllerProvider`
- `calendarHeatmapProvider`
- `yearReviewProvider`
- `shareCardGeneratorProvider`
- `sharePreviewProvider`

Design notes:

- heatmap providers should depend on diary data providers, not re-query local DB independently inside widgets
- check-in actions should accept a `MatchEntry` or `entryId` and use diary providers for mutation
- notification providers should remain app-level and reusable by later features

---

## Routing Integration

Expected route additions or wiring:

- `Routes.notificationSettings`
- `Routes.calendarHeatmap`
- `Routes.stadiumCheckIn`
- `Routes.sharePreview`

The router should remain centralized. Notification tap routing must resolve destinations through `NotificationHandler`, not by hardcoding route logic inside Firebase callbacks or widgets.

---

## Permissions and Privacy

### Location

Location must be requested only when the user explicitly initiates check-in. The app should not maintain background tracking for this feature.

### Notifications

Notification permission should be requested with context and reflected honestly in settings UI.

### Sharing

Share cards should remain local exports:

- generated on-device
- shown to the user before sharing
- sent through the system share sheet
- not auto-posted anywhere inside MatchLog

---

## Testing Strategy

### Unit Tests

- check-in eligibility logic
- notification preference mapping
- year-review/share-card aggregate formatting

### Widget Tests

- `calendar_heatmap_test.dart`
- `stadium_check_in_screen_test.dart`
- `notification_settings_screen_test.dart`
- `share_preview_screen_test.dart`

### Service Tests

- notification channel registration
- notification tap routing
- share-card generation returns valid image bytes

### Property-Based Correctness

Properties that should be tested with generated inputs where practical:

1. heatmap day counts sum to total entries in the rendered range
2. `currentStreak <= longestStreak`
3. supported share-card templates produce non-empty images at requested dimensions
4. every supported notification type maps to a deterministic destination or safe no-op
