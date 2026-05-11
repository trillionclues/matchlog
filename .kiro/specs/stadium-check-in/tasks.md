# Implementation Plan: Stadium Check-In

## Overview

Implement the Stadium Check-In feature as a thin vertical slice through all four Clean Architecture layers. The plan follows the dependency order: domain interfaces first, then data layer implementations, then presentation layer, then routing and UI wiring. Each task builds directly on the previous one so there is no orphaned code at any checkpoint.

All code is Dart/Flutter. State management uses Riverpod `StateNotifier`. Local persistence uses Drift. Remote sync uses Firestore. Navigation uses GoRouter. Error handling uses `fpdart` `Either`. Immutable state uses `freezed`. Property-based tests use `kiri_check`.

## Tasks

- [x] 1. Implement the `CheckInEligibility` pure predicate
  - Create `lib/features/diary/domain/usecases/check_in_eligibility.dart`
  - Implement `bool call(MatchEntry entry, {DateTime? now})` checking all three conditions: `watchType == 'stadium'`, `geoVerified == false`, and `createdAt` calendar date equals today in device local timezone
  - The `now` parameter must be injectable so tests can control the clock
  - No side effects, no dependencies — this is a pure function
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [x] 2. Extend `DiaryRepository` interface and implement data layer
  - [x] 2.1 Add `updateGeoVerified` to the `DiaryRepository` interface
    - Open `lib/features/diary/domain/repositories/diary_repository.dart`
    - Add `Future<Either<DiaryFailure, Unit>> updateGeoVerified({required String userId, required String entryId, required bool geoVerified})`
    - _Requirements: 8.1, 8.2_

  - [x] 2.2 Add `updateGeoVerified` DAO method to `MatchDao`
    - Open `lib/core/database/daos/match_dao.dart`
    - Add `Future<void> updateGeoVerified(String id, bool geoVerified)` using a targeted `update` + `write` with `MatchEntriesCompanion(geoVerified: Value(geoVerified))` — must not overwrite other fields
    - _Requirements: 8.3_

  - [x] 2.3 Add `updateGeoVerified` to `DiaryLocalSource`
    - Open `lib/features/diary/data/diary_local_source.dart`
    - Add `Future<void> updateGeoVerified(String id, bool geoVerified)` delegating to `_dao.updateGeoVerified`
    - _Requirements: 8.3_

  - [x] 2.4 Add `updateGeoVerified` to `DiaryFirebaseSource`
    - Open `lib/features/diary/data/diary_firebase_source.dart`
    - Add `Future<void> updateGeoVerified({required String userId, required String entryId, required bool geoVerified})` using a targeted `.update({'geoVerified': geoVerified, 'updatedAt': FieldValue.serverTimestamp()})` — must not overwrite the full document
    - _Requirements: 8.3, 8.4_

  - [x] 2.5 Implement `updateGeoVerified` in `DiaryRepositoryImpl`
    - Open `lib/features/diary/data/diary_repository_impl.dart`
    - Implement the offline-first pattern: local write first (success boundary), then if online fire-and-forget remote update with `catchError` that enqueues, else enqueue directly
    - Enqueue payload: `{"operation": "updateGeoVerified", "collection": "match_entries", "documentId": "<entryId>", "payload": "{\"userId\": \"<userId>\", \"geoVerified\": true}"}`
    - Return `Right(unit)` on local success; return `Left(DiaryFailure.storage(...))` only if the local Drift write throws
    - _Requirements: 5.2, 5.3, 5.4, 5.6, 8.4, 8.5_

- [x] 3. Checkpoint — compile and verify data layer
  - Ensure all files compile with no errors (`dart analyze`)
  - Confirm `DiaryRepository` interface, `MatchDao`, `DiaryLocalSource`, `DiaryFirebaseSource`, and `DiaryRepositoryImpl` are consistent
  - Ask the user if any questions arise before proceeding

- [x] 4. Implement `LocationService` and `GeocodingService`
  - [x] 4.1 Create `LocationService`
    - Create `lib/features/diary/data/location_service.dart`
    - Define `enum LocationPermissionStatus { granted, denied, permanentlyDenied, serviceDisabled }`
    - Implement `Future<LocationPermissionStatus> requestPermission()` using `Geolocator.isLocationServiceEnabled()` and `Geolocator.requestPermission()`
    - Implement `Future<Position> getCurrentPosition({Duration timeout = const Duration(seconds: 15)})` using `Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium)` with the timeout applied via `.timeout()`
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.1, 3.5_

  - [x] 4.2 Create `GeocodingService`
    - Create `lib/features/diary/data/geocoding_service.dart`
    - Implement `Future<String?> reverseGeocode(Position position)` calling `placemarkFromCoordinates(lat, lng)` and formatting the first result as `"${placemark.name}, ${placemark.locality}"`
    - Return `null` on exception or empty result list — never throw
    - _Requirements: 3.2, 3.4, 3.6_

- [x] 5. Implement `UpdateGeoVerified` use case
  - Create `lib/features/diary/domain/usecases/update_geo_verified.dart`
  - Implement `Future<Either<DiaryFailure, Unit>> call({required String userId, required String entryId})` delegating to `_repository.updateGeoVerified(userId: userId, entryId: entryId, geoVerified: true)`
  - The use case always passes `geoVerified: true` — it is the only caller of this mutation path
  - _Requirements: 5.1, 5.7_

- [x] 6. Implement `CheckInState` and `CheckInController`
  - [x] 6.1 Create `CheckInState` Freezed union and `CheckInController` StateNotifier
    - Create `lib/features/diary/presentation/providers/check_in_providers.dart`
    - Define `@freezed sealed class CheckInState` with variants: `idle`, `requestingPermission`, `acquiringLocation`, `geocoding`, `locationAcquired({required String venueDescription, required double latitude, required double longitude})`, `updatingEntry`, `verified`, `permissionDenied({String? message})`, `permissionPermanentlyDenied({String? message})`, `locationServiceDisabled({String? message})`, `acquisitionFailed({String? message})`, `updateFailed({String? message})`
    - _Requirements: 2.4, 2.5, 2.6, 3.3, 3.4, 3.5, 5.5, 5.6, 7.2_

  - [x] 6.2 Implement `CheckInController.startCheckIn()`
    - Implement the full state machine: eligibility guard → `requestingPermission` → permission switch → `acquiringLocation` → GPS with 15 s timeout → `geocoding` → reverse geocode with coordinate fallback → `locationAcquired`
    - If `_eligibility(entry)` returns `false`, return immediately without requesting permission (no-op)
    - Map each `LocationPermissionStatus` to the correct failure state
    - Catch `TimeoutException` from GPS and transition to `acquisitionFailed` with the user-facing message
    - _Requirements: 1.2, 1.5, 2.1, 2.3, 2.4, 2.5, 2.6, 3.1, 3.3, 3.4, 3.5_

  - [x] 6.3 Implement `CheckInController.confirm()` and `cancel()`
    - `confirm()`: guard that state is `_LocationAcquired`, transition to `updatingEntry`, call `_updateGeoVerified`, fold result to `verified` or `updateFailed`
    - `cancel()` and `reset()`: transition to `idle`
    - `geoVerified` MUST only be set inside `confirm()` — no other code path may call `_updateGeoVerified`
    - _Requirements: 4.2, 4.3, 5.1, 5.5, 5.6, 5.7_

  - [x] 6.4 Wire Riverpod providers for check-in
    - In the same file, add providers: `checkInEligibilityProvider`, `locationServiceProvider`, `geocodingServiceProvider`, `updateGeoVerifiedUseCaseProvider`, and `checkInControllerProvider` (a `StateNotifierProvider.autoDispose.family<CheckInController, CheckInState, String>` keyed on `userId`)
    - Follow the same provider wiring pattern as `logMatchControllerProvider` and `deleteEntryControllerProvider` in `diary_providers.dart`
    - _Requirements: 5.1_

- [x] 7. Checkpoint — run `build_runner` and verify generated code
  - Run `dart run build_runner build --delete-conflicting-outputs` to generate `check_in_providers.freezed.dart`
  - Ensure `dart analyze` reports no errors across all new and modified files
  - Ask the user if any questions arise before proceeding

- [x] 8. Create `StadiumCheckInScreen`
  - Create `lib/features/diary/presentation/screens/stadium_check_in_screen.dart`
  - Accept `entryId` as a constructor parameter; load the entry via `matchEntryDetailProvider`
  - Watch `checkInControllerProvider` and render each `CheckInState` variant:
    - `idle` / `requestingPermission`: `CircularProgressIndicator` + "Requesting location permission…"
    - `acquiringLocation` / `geocoding`: `CircularProgressIndicator` + "Finding your location…"
    - `locationAcquired`: venue description card, honor-system disclaimer text, `FilledButton` "Confirm Check-In", `OutlinedButton` "Cancel"
    - `updatingEntry`: `CircularProgressIndicator` + "Saving…"
    - `verified`: success icon, "You're checked in!", auto-pop after 1.5 s using `Future.delayed` + `context.pop()`
    - `permissionDenied` / `locationServiceDisabled`: error icon, message, "Dismiss" button that calls `controller.reset()` and `context.pop()`
    - `permissionPermanentlyDenied`: error icon, message, "Open Settings" button calling `Geolocator.openAppSettings()`, "Dismiss" button
    - `acquisitionFailed` / `updateFailed`: error icon, message, "Retry" button calling `startCheckIn` or `confirm` again, "Dismiss" button
  - Call `controller.startCheckIn(entry)` in `initState` / `didChangeDependencies` once the entry is loaded
  - _Requirements: 2.5, 3.3, 3.4, 4.1, 4.4, 5.5, 5.6, 7.2, 7.3, 7.4, 7.5_

- [x] 9. Add routing for `stadiumCheckIn`
  - [x] 9.1 Add route constant and path builder to `Routes`
    - Open `lib/core/router/routes.dart`
    - Add `static const String stadiumCheckIn = '/diary/:id/check-in'`
    - Add `static String stadiumCheckInPath(String id) => '/diary/$id/check-in'`
    - _Requirements: 9.1_

  - [x] 9.2 Register `GoRoute` in `AppRouter`
    - Open `lib/core/router/app_router.dart`
    - Add a `GoRoute` for `Routes.stadiumCheckIn` as a top-level sibling route (outside `StatefulShellRoute`) with `name: 'stadiumCheckIn'` and builder returning `StadiumCheckInScreen(entryId: state.pathParameters['id'] ?? '')`
    - Import `StadiumCheckInScreen`
    - _Requirements: 9.2, 9.3, 9.4_

- [x] 10. Add "Check In" button to `MatchDetailScreen`
  - Open `lib/features/diary/presentation/screens/match_detail_screen.dart`
  - Import `CheckInEligibility` and `Routes`
  - Inside the `data` branch of `entryAsync.when`, after the metadata `Wrap` and before the rating stars, add a `FilledButton.tonal` wrapped in `if (CheckInEligibility()(entry))`:
    - Icon: `Icons.location_on_outlined`, label: "Check In"
    - `onPressed`: `context.push(Routes.stadiumCheckInPath(widget.entryId))`
  - The button must not appear when `geoVerified == true`, `watchType != 'stadium'`, or `matchDate != today` — all three are handled by `CheckInEligibility`
  - _Requirements: 1.4, 1.6, 6.2, 9.2_

- [x] 11. Checkpoint — full compile and manual smoke test
  - Run `dart analyze` across the project; fix any remaining issues
  - Verify the "Check In" button appears on a today stadium entry and is absent on TV entries, past entries, and already-verified entries
  - Ask the user if any questions arise before proceeding

- [ ] 12. Write unit tests for `CheckInController`
  - Create `test/features/diary/check_in_controller_test.dart`
  - Use `mocktail` to mock `LocationService`, `GeocodingService`, and `UpdateGeoVerified`
  - Cover all ten state-machine paths from the design's Testing Strategy:
    - [ ] 12.1 Happy path: permission granted → position acquired → geocoding succeeds → `locationAcquired` → confirm → `verified`
      - _Requirements: 10.1_
    - [ ]* 12.2 Permission denied: state transitions to `permissionDenied`, `UpdateGeoVerified` never called
      - _Requirements: 10.1_
    - [ ]* 12.3 Permission permanently denied: state transitions to `permissionPermanentlyDenied`
      - _Requirements: 10.1_
    - [ ]* 12.4 Location service disabled: state transitions to `locationServiceDisabled`
      - _Requirements: 10.1_
    - [ ]* 12.5 GPS timeout: state transitions to `acquisitionFailed` after mock `TimeoutException`
      - _Requirements: 10.1_
    - [ ]* 12.6 Geocoding failure fallback: state transitions to `locationAcquired` with coordinate string, not an error state
      - _Requirements: 10.1_
    - [ ]* 12.7 User cancels at confirmation: state returns to `idle`, `UpdateGeoVerified` never called
      - _Requirements: 10.3_
    - [ ]* 12.8 Local write failure: state transitions to `updateFailed`, `geoVerified` not mutated
      - _Requirements: 10.1_
    - [ ]* 12.9 Ineligible entry (non-stadium): `startCheckIn()` is a no-op, no permission request
      - _Requirements: 10.2_
    - [ ]* 12.10 Ineligible entry (non-today): `startCheckIn()` is a no-op, no permission request
      - _Requirements: 10.2_

- [ ] 13. Write property-based tests for `CheckInEligibility`
  - Create `test/features/diary/check_in_eligibility_test.dart`
  - Use `kiri_check` `Arbitrary` generators to produce random `MatchEntry` instances
  - Each property runs a minimum of 100 iterations
  - Tag each test with `// Feature: stadium-check-in, Property N: <property_text>`

  - [ ] 13.1 Write property test for Property 1: Non-stadium entries are never eligible
    - Generate entries with `watchType` drawn from `['tv', 'streaming', 'radio']` (and any other non-stadium string)
    - Assert `CheckInEligibility()(entry)` is `false` for all generated entries
    - **Property 1: Non-stadium entries are never eligible**
    - **Validates: Requirements 1.1, 1.2, 10.4**

  - [ ] 13.2 Write property test for Property 2: Non-today entries are never eligible
    - Generate entries with `watchType == 'stadium'`, `geoVerified == false`, and `createdAt` on any date that is not today's calendar date
    - Assert `CheckInEligibility()(entry)` is `false` for all generated entries
    - **Property 2: Non-today entries are never eligible**
    - **Validates: Requirements 1.5, 1.6, 10.5**

  - [ ] 13.3 Write property test for Property 3: Already-verified entries are never eligible
    - Generate entries with `watchType == 'stadium'` and `geoVerified == true` (any `createdAt`)
    - Assert `CheckInEligibility()(entry)` is `false` for all generated entries
    - **Property 3: Already-verified entries are never eligible**
    - **Validates: Requirements 1.3**

  - [ ] 13.4 Write property test for Property 4: Eligible entries satisfy all three conditions simultaneously
    - Generate entries with `watchType == 'stadium'`, `geoVerified == false`, and `createdAt` on today's calendar date (varying hour and minute)
    - Assert `CheckInEligibility()(entry)` is `true` for all generated entries
    - **Property 4: Eligible entries satisfy all three conditions simultaneously**
    - **Validates: Requirements 1.4, 10.6**

  - [ ] 13.5 Write property test for Property 5: `geoVerified` is never set without explicit confirmation
    - Generate sequences of `CheckInController` events that do not include a `confirm()` call (e.g., `startCheckIn`, `cancel`, `reset`, and various permission/GPS failure paths)
    - For each sequence, assert that `mockUpdateGeoVerified` is never invoked
    - **Property 5: geoVerified is never set without explicit confirmation**
    - **Validates: Requirements 5.7, 4.3**

- [ ] 14. Write repository unit tests for `updateGeoVerified`
  - Create `test/features/diary/update_geo_verified_repository_test.dart`
  - Use `mocktail` to mock `DiaryLocalSource`, `DiaryFirebaseSource`, and `AppDatabase`
  - Cover the four paths from the design's Testing Strategy:
    - [ ] 14.1 Online path: local write succeeds → remote `updateGeoVerified` called
      - _Requirements: 5.2, 5.3, 8.4_
    - [ ]* 14.2 Offline path: local write succeeds → sync queue entry created, remote not called
      - _Requirements: 5.4, 8.4_
    - [ ]* 14.3 Remote failure (online): local write succeeds → remote throws → sync queue entry created, `Right(unit)` returned
      - _Requirements: 5.3, 8.4_
    - [ ]* 14.4 Local write failure: Drift throws → `Left(DiaryFailure.storage(...))` returned, remote never called
      - _Requirements: 5.6_

- [ ] 15. Final checkpoint — run full test suite
  - Run `flutter test` and ensure all new tests pass
  - Run `dart analyze` and confirm zero errors
  - Ask the user if any questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Each task references specific requirements for traceability
- Checkpoints at tasks 3, 7, 11, and 15 ensure incremental validation
- Property tests (task 13) validate universal correctness of the eligibility predicate across the full input space
- Unit tests (tasks 12 and 14) validate specific state-machine transitions and repository paths with deterministic mocks
- The `geoVerified` mutation is structurally confined to `CheckInController.confirm()` — no other code path may call `UpdateGeoVerified`
- No new package dependencies are introduced; `geolocator`, `geocoding`, `kiri_check`, and `freezed` are already in `pubspec.yaml`
