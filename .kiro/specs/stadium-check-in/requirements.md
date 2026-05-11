# Requirements Document

## Introduction

Stadium Check-In is a Phase 1.5 feature that lets users verify they were physically present at a stadium when logging a match. It upgrades the existing `geoVerified` field on `MatchEntry` from a passive flag to an actively earned badge.

The flow is intentionally pragmatic: rather than matching GPS coordinates against a stadium boundary database (which does not exist in the app), it uses an "honor system with GPS evidence" approach. The app reads the user's current position, reverse-geocodes it to a human-readable venue description, presents that description to the user for confirmation, and — on confirmation — marks the entry as verified. This keeps the feature honest about what it can actually prove while still giving the diary meaningful signal.

The feature is scoped to entries where `watchType == 'stadium'`. It is triggered from the match detail screen. It must never request location in the background, must degrade gracefully on permission denial, and must never mutate `geoVerified` to `true` without explicit user confirmation.

---

## Glossary

- **Stadium_Check_In_Flow**: The end-to-end user journey from tapping "Check In" on a match detail screen through GPS acquisition, reverse geocoding, confirmation, and `geoVerified` update.
- **Check_In_Controller**: The Riverpod `StateNotifier` that orchestrates the Stadium_Check_In_Flow and exposes its state to the UI.
- **Location_Service**: The wrapper around the `geolocator` package responsible for requesting permission and reading the current GPS position.
- **Geocoding_Service**: The wrapper around the `geocoding` package responsible for converting a GPS coordinate into a human-readable venue or address string.
- **GeoVerified**: The boolean field on `MatchEntry` that is `true` when a stadium check-in has been confirmed by the user.
- **Eligible_Entry**: A `MatchEntry` with `watchType == 'stadium'`, `geoVerified == false`, and `matchDate == today` (the entry's match date matches the current calendar date in the device's local timezone).
- **Match_Date**: The calendar date (year, month, day) of the match as stored on the `MatchEntry`, compared against the device's current local date to determine same-day eligibility.
- **Verified_Badge**: The visual indicator (chip or icon) shown in the diary feed and match detail screen when `geoVerified == true`.
- **Diary_Repository**: The existing `DiaryRepository` interface used for local Drift writes and Firestore sync.

---

## Requirements

### Requirement 1: Check-In Eligibility

**User Story:** As a user, I want the check-in option to appear only on relevant diary entries for today's matches, so that I am never prompted to verify a past match I can no longer be physically present for.

#### Acceptance Criteria

1. THE Stadium_Check_In_Flow SHALL be accessible only from a `MatchEntry` where `watchType == 'stadium'`.
2. WHEN a `MatchEntry` has `watchType != 'stadium'`, THE Check_In_Controller SHALL reject the check-in attempt and SHALL not request location permission.
3. WHEN a `MatchEntry` already has `geoVerified == true`, THE UI SHALL display the Verified_Badge and SHALL not offer a second check-in action.
4. THE match detail screen SHALL display a "Check In" action only when the entry is an Eligible_Entry.
5. WHEN a `MatchEntry` has a `matchDate` that does not equal today's date in the device's local timezone, THE Check_In_Controller SHALL reject the check-in attempt and SHALL not request location permission.
6. THE UI SHALL not display a "Check In" action on any diary entry whose `matchDate` is not today, regardless of `watchType` or `geoVerified` state.
7. THE same-day restriction prevents retroactive verification of past matches and prevents a user physically present at a venue from verifying unrelated prior entries at the same location.

---

### Requirement 2: Location Permission Handling

**User Story:** As a user, I want the app to ask for location permission only when I explicitly tap "Check In", so that my location is never accessed without my knowledge.

#### Acceptance Criteria

1. THE Location_Service SHALL request location permission only when the user explicitly initiates the Stadium_Check_In_Flow.
2. THE app SHALL not request location permission in the background or at app launch for this feature.
3. WHEN location permission is granted, THE Location_Service SHALL proceed to read the current GPS position.
4. WHEN location permission is denied by the user, THE Check_In_Controller SHALL transition to a `permissionDenied` state and SHALL not attempt GPS acquisition.
5. WHEN location permission is permanently denied (requires settings), THE Check_In_Controller SHALL transition to a `permissionPermanentlyDenied` state and SHALL present guidance to open device settings.
6. IF the device does not support location services, THEN THE Check_In_Controller SHALL transition to a `locationServiceDisabled` state.

---

### Requirement 3: GPS Acquisition and Reverse Geocoding

**User Story:** As a user, I want the app to show me where it thinks I am before I confirm, so that I can verify the location makes sense.

#### Acceptance Criteria

1. WHEN location permission is granted, THE Location_Service SHALL acquire the current GPS position with at least medium accuracy.
2. WHEN a GPS position is acquired, THE Geocoding_Service SHALL reverse-geocode the coordinates into a human-readable venue or address string.
3. WHEN reverse geocoding succeeds, THE Check_In_Controller SHALL transition to a `locationAcquired` state containing the venue description and coordinates.
4. IF reverse geocoding fails or returns no results, THEN THE Check_In_Controller SHALL fall back to displaying the raw coordinates as the location description.
5. IF GPS acquisition times out after 15 seconds, THEN THE Check_In_Controller SHALL transition to a `acquisitionFailed` state and SHALL inform the user.
6. THE Geocoding_Service SHALL use the `geocoding` package already present in `pubspec.yaml` and SHALL not introduce a new geocoding dependency.

---

### Requirement 4: User Confirmation Step

**User Story:** As a user, I want to confirm the detected location before my entry is marked as verified, so that I remain in control of what gets recorded.

#### Acceptance Criteria

1. WHEN the Check_In_Controller is in `locationAcquired` state, THE UI SHALL present the venue description to the user with a confirm and a cancel action.
2. WHEN the user confirms, THE Check_In_Controller SHALL proceed to update `geoVerified`.
3. WHEN the user cancels, THE Check_In_Controller SHALL return to idle state and SHALL not modify the `MatchEntry`.
4. THE confirmation UI SHALL make clear that the check-in is based on the user's current GPS location and is an honor-system verification.

---

### Requirement 5: GeoVerified Update

**User Story:** As a user, I want my diary entry to reflect the verified status immediately after I confirm, so that the badge appears without needing to refresh.

#### Acceptance Criteria

1. WHEN the user confirms the location, THE Check_In_Controller SHALL call the Diary_Repository to update the `MatchEntry` with `geoVerified = true`.
2. THE Diary_Repository SHALL persist the `geoVerified = true` update to the local Drift database first, consistent with the existing offline-first contract.
3. WHEN the device is online, THE Diary_Repository SHALL sync the updated `geoVerified` field to Firestore as a best-effort background operation.
4. WHEN the device is offline, THE Diary_Repository SHALL enqueue the sync operation for later delivery, consistent with the existing sync queue pattern.
5. WHEN the update succeeds, THE Check_In_Controller SHALL transition to a `verified` state.
6. IF the local write fails, THEN THE Check_In_Controller SHALL transition to an `updateFailed` state and SHALL not set `geoVerified = true`.
7. THE Check_In_Controller SHALL never set `geoVerified = true` without a preceding explicit user confirmation in the same flow session.

---

### Requirement 6: Verified Badge Display

**User Story:** As a user, I want to see a clear verified badge on my stadium entries, so that I can distinguish entries I physically attended from those I only logged.

#### Acceptance Criteria

1. WHEN a `MatchEntry` has `geoVerified == true`, THE diary feed SHALL display the Verified_Badge on the corresponding `MatchCard`.
2. WHEN a `MatchEntry` has `geoVerified == true`, THE match detail screen SHALL display the Verified_Badge alongside the other metadata chips.
3. THE Verified_Badge SHALL use the app's existing color tokens and SHALL be visually distinct from unverified stadium entries.
4. THE `MatchCard` widget already renders a Verified_Badge when `geoVerified == true`; THE feature SHALL not duplicate or replace that existing rendering logic.

---

### Requirement 7: Graceful Failure and Non-Blocking Behavior

**User Story:** As a user, I want check-in failures to be informative but non-disruptive, so that a GPS problem never prevents me from viewing or keeping my diary entry.

#### Acceptance Criteria

1. WHEN the Stadium_Check_In_Flow fails for any reason (permission denied, GPS timeout, update error), THE diary entry SHALL remain accessible and unmodified.
2. THE Check_In_Controller SHALL expose a human-readable error message for each failure state.
3. THE UI SHALL display the failure reason and SHALL offer a dismiss or retry action as appropriate.
4. IF the check-in flow is dismissed or fails, THEN the match detail screen SHALL remain navigable and SHALL not be in an error state.
5. THE feature SHALL not display a loading indicator for longer than the GPS acquisition timeout (15 seconds) without transitioning to a failure state.

---

### Requirement 8: Repository Contract Extension

**User Story:** As a developer, I want a dedicated update method for `geoVerified` on the Diary_Repository, so that the check-in feature does not need to re-log the entire entry to flip one field.

#### Acceptance Criteria

1. THE Diary_Repository interface SHALL expose a method to update `geoVerified` for a given entry ID and user ID.
2. THE method SHALL accept `entryId`, `userId`, and the new `geoVerified` value as parameters.
3. THE implementation SHALL update only the `geoVerified` field in the local Drift row and SHALL not overwrite other entry fields.
4. THE implementation SHALL sync the field change to Firestore using the existing online/offline-queue pattern.
5. WHEN the update method is called with `geoVerified = true` for an entry that already has `geoVerified = true`, THE implementation SHALL treat the call as a no-op and SHALL return success.

---

### Requirement 9: Routing Integration

**User Story:** As a developer, I want the stadium check-in screen wired into GoRouter, so that it follows the same navigation patterns as the rest of the app.

#### Acceptance Criteria

1. THE feature SHALL add a `stadiumCheckIn` route constant to `Routes` under a path scoped to the diary entry, such as `/diary/:id/check-in`.
2. THE match detail screen SHALL navigate to the stadium check-in route using `context.push` with the entry ID.
3. THE stadium check-in screen SHALL be able to pop back to the match detail screen on completion, cancellation, or failure.
4. THE router SHALL not require authentication state changes to access the check-in route; existing auth guards on the diary section are sufficient.

---

### Requirement 10: Testing and Correctness

**User Story:** As a developer, I want automated tests covering the check-in state machine and eligibility rules, so that permission and GPS edge cases do not regress.

#### Acceptance Criteria

1. THE test suite SHALL include unit tests for the Check_In_Controller covering: successful flow, permission denied, permanent permission denial, GPS timeout, reverse geocoding fallback, user cancellation, and local write failure.
2. THE test suite SHALL include a unit test verifying that the Check_In_Controller rejects check-in attempts for entries with `watchType != 'stadium'`.
3. THE test suite SHALL include a unit test verifying that the Check_In_Controller does not set `geoVerified = true` when the user cancels at the confirmation step.
4. FOR ALL `MatchEntry` values where `watchType != 'stadium'`, THE eligibility check SHALL return `false`.
5. FOR ALL `MatchEntry` values where `watchType == 'stadium'` and `geoVerified == false` and `matchDate != today`, THE eligibility check SHALL return `false`.
6. FOR ALL `MatchEntry` values where `watchType == 'stadium'` and `geoVerified == false` and `matchDate == today`, THE eligibility check SHALL return `true`.
7. THE test suite SHALL include a widget test verifying that the Verified_Badge is visible on the match detail screen when `geoVerified == true` and absent when `geoVerified == false`.
