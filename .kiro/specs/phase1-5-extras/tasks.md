# Implementation Tasks: Phase 1.5 Extras

## Tasks

- [ ] 1. Spec and dependency alignment
  - [ ] 1.1 Treat `.kiro/specs/phase1-5-extras/` as the canonical implementation spec for the Phase 1.5 extras scope
  - [ ] 1.2 Reuse existing Phase 1 infrastructure (`AppDatabase`, diary providers, stats models, routes, design tokens, and shared widgets) instead of creating parallel systems
  - [ ] 1.3 Keep notifications in `lib/core/notifications/` and keep diary or share-specific logic out of core where it does not belong

- [ ] 2. Stadium check-in
  - [ ] 2.1 Add the presentation flow for stadium check-in on eligible stadium-watch diary entries
  - [ ] 2.2 Request location permission only when the user initiates check-in
  - [ ] 2.3 Implement verification logic that can upgrade `MatchEntry.geoVerified` to `true` only on successful validation
  - [ ] 2.4 Ensure failed verification, denied permission, or unsupported context leaves `geoVerified` as `false`
  - [ ] 2.5 Surface verified status back into diary feed and detail UI as a visible badge or chip

- [ ] 3. Calendar heatmap
  - [ ] 3.1 Implement `calendar_heatmap.dart` as a `CustomPainter`-based activity heatmap using diary-entry data
  - [ ] 3.2 Aggregate diary entries by calendar day and map counts into documented intensity tiers
  - [ ] 3.3 Add day-cell tap behavior to inspect matches from the selected day
  - [ ] 3.4 Reuse the same streak computation logic used by diary stats
  - [ ] 3.5 Add empty-state handling for users without diary history

- [ ] 4. Core notifications
  - [ ] 4.1 Implement `lib/core/notifications/channels.dart`
  - [ ] 4.2 Implement `lib/core/notifications/notification_service.dart` for FCM setup and local notification rendering
  - [ ] 4.3 Implement `lib/core/notifications/notification_handler.dart` for notification tap routing
  - [ ] 4.4 Implement `lib/core/notifications/notification_queue.dart` only to the extent needed for documented batching or offline edge cases
  - [ ] 4.5 Register the documented Android channels: `match_reminders`, `bet_settlements`, `social_activity`, `weekly_digest`, and `ai_insights`

- [ ] 5. Notification settings
  - [ ] 5.1 Add a notification settings surface matching the Phase 1.5 screen inventory
  - [ ] 5.2 Read and write the documented notification preference fields under the user settings model
  - [ ] 5.3 Reflect OS-level permission denial clearly in the settings UI
  - [ ] 5.4 Ensure delivery logic respects saved notification preferences

- [ ] 6. Share-card generation
  - [ ] 6.1 Implement reusable share-card rendering via `RepaintBoundary.toImage()`
  - [ ] 6.2 Support portrait, square, and landscape card variants
  - [ ] 6.3 Implement at least one recap-style template and one lightweight stat-sharing template
  - [ ] 6.4 Open the platform share sheet using locally generated image output
  - [ ] 6.5 Keep sharing external-only and do not post to an internal feed

- [ ] 7. Recap and year-review compatibility
  - [ ] 7.1 Implement or wire aggregate recap generation compatible with the documented `YearReview` model
  - [ ] 7.2 Ensure share-card templates can consume recap data such as total matches, ROI, top team, stadium visits, and streaks
  - [ ] 7.3 Keep the share-card infrastructure reusable for a later full wrapped or year-review screen

- [ ] 8. Providers and routing
  - [ ] 8.1 Add Riverpod providers for notification services and preferences
  - [ ] 8.2 Add Riverpod providers for stadium check-in actions and heatmap data
  - [ ] 8.3 Add Riverpod providers for recap data and share-card generation state
  - [ ] 8.4 Wire routes for notification settings, calendar heatmap, stadium check-in, and share preview as needed
  - [ ] 8.5 Keep notification tap navigation centralized in `NotificationHandler`

- [ ] 9. Privacy and permissions
  - [ ] 9.1 Ensure location is requested only during explicit check-in
  - [ ] 9.2 Ensure notification permissions are requested explicitly and handled gracefully
  - [ ] 9.3 Keep share-card generation local to the device unless a later feature explicitly adds remote upload
  - [ ] 9.4 Keep persisted settings and generated artifacts compatible with account-deletion expectations

- [ ] 10. Testing
  - [ ] 10.1 Add tests for stadium check-in success, denial, and ineligible-entry behavior
  - [ ] 10.2 Add widget tests for `calendar_heatmap.dart` day selection and empty-state behavior
  - [ ] 10.3 Add tests for notification channel registration, preference gating, and tap routing
  - [ ] 10.4 Add tests for share-card generation and share-preview rendering
  - [ ] 10.5 Add property-based tests for heatmap counts, streak ordering, share-card output dimensions, and notification routing determinism

- [ ] 11. Verification and cleanup
  - [ ] 11.1 Run `dart run build_runner build --delete-conflicting-outputs`
  - [ ] 11.2 Run `flutter test`
  - [ ] 11.3 Run `flutter analyze`
  - [ ] 11.4 Manually verify the Phase 1.5 flows: stadium check-in -> verified diary badge; open heatmap -> inspect day; receive notification -> tap to route; generate share card -> preview -> share
