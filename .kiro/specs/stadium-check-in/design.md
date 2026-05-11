# Design Document: Stadium Check-In

## Overview

Stadium Check-In upgrades the existing `geoVerified` field on `MatchEntry` from a passive boolean into an actively earned badge. When a user logs a stadium match on the day of the game, a "Check In" action appears on the match detail screen. Tapping it triggers a GPS acquisition + reverse geocoding flow, presents the detected location for confirmation, and — on explicit user confirmation — flips `geoVerified` to `true` via the existing offline-first repository.

The approach is deliberately pragmatic: the app cannot verify that a user is inside a specific stadium boundary (no stadium polygon database exists), so it uses an honor-system model. GPS evidence is collected and shown to the user; the user confirms it is accurate. This is honest about what the system can prove while still giving the diary meaningful signal.

The same-day constraint (`matchDate == today`) is the critical anti-exploit guard. It prevents retroactive verification of past matches and closes the "venue squatter" exploit where a user physically present at a stadium could verify old entries logged at the same location.

### Scope

- New files: `CheckInEligibility` use case, `UpdateGeoVerified` use case, `LocationService`, `GeocodingService`, `StadiumCheckInScreen`, `CheckInController` + providers.
- Modified files: `DiaryRepository` interface, `MatchDao`, `DiaryLocalSource`, `DiaryRepositoryImpl`, `DiaryFirebaseSource`, `MatchDetailScreen`, `Routes`, `AppRouter`.
- No new package dependencies — `geolocator` and `geocoding` are already in `pubspec.yaml`.

---

## Architecture

The feature follows the existing Clean Architecture, feature-first structure. The check-in flow is a thin vertical slice through all four layers.

```
Presentation          Domain                  Data
─────────────         ──────────────────      ──────────────────────────
StadiumCheckIn        CheckInEligibility      LocationService
Screen                (pure predicate)        (geolocator wrapper)
    │                                         GeocodingService
    │                 UpdateGeoVerified        (geocoding wrapper)
    │                 (use case)              DiaryLocalSource
    │                     │                   .updateGeoVerified()
CheckInController         │                   DiaryFirebaseSource
(StateNotifier)           │                   .updateGeoVerified()
    │                 DiaryRepository         DiaryRepositoryImpl
    └─────────────────── interface ──────────── .updateGeoVerified()
                      .updateGeoVerified()
```

### State Machine

The `CheckInController` is a `StateNotifier<CheckInState>`. The state transitions are:

```
idle
  │  startCheckIn() called
  ▼
requestingPermission
  │  granted                    │  denied              │  permanently denied  │  service disabled
  ▼                             ▼                      ▼                      ▼
acquiringLocation          permissionDenied   permissionPermanentlyDenied  locationServiceDisabled
  │  position acquired
  ▼
geocoding
  │  success                    │  failure (fallback to coords)
  ▼                             ▼
locationAcquired (venue string or coordinate string)
  │  user confirms              │  user cancels
  ▼                             ▼
updatingEntry               idle
  │  success                    │  local write fails
  ▼                             ▼
verified                   updateFailed
```

All terminal failure states expose a `message` string and an `allowRetry` flag so the UI can offer appropriate recovery actions.

---

## Components and Interfaces

### Domain Layer

#### `CheckInEligibility` — Pure Eligibility Predicate

```dart
// lib/features/diary/domain/usecases/check_in_eligibility.dart

class CheckInEligibility {
  /// Returns true iff the entry is eligible for stadium check-in.
  ///
  /// Eligibility requires ALL of:
  ///   1. watchType == 'stadium'
  ///   2. geoVerified == false
  ///   3. matchDate (year/month/day of createdAt) == today in device local timezone
  bool call(MatchEntry entry, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final matchDate = entry.createdAt;
    final sameDay = matchDate.year == today.year &&
        matchDate.month == today.month &&
        matchDate.day == today.day;
    return entry.watchType == 'stadium' &&
        !entry.geoVerified &&
        sameDay;
  }
}
```

The `now` parameter is injectable for deterministic testing. This is a pure function with no side effects.

#### `UpdateGeoVerified` — Use Case

```dart
// lib/features/diary/domain/usecases/update_geo_verified.dart

class UpdateGeoVerified {
  final DiaryRepository _repository;
  UpdateGeoVerified(this._repository);

  Future<Either<DiaryFailure, Unit>> call({
    required String userId,
    required String entryId,
  }) {
    return _repository.updateGeoVerified(
      userId: userId,
      entryId: entryId,
      geoVerified: true,
    );
  }
}
```

#### `DiaryRepository` — Extended Interface

Add one method to the existing interface:

```dart
Future<Either<DiaryFailure, Unit>> updateGeoVerified({
  required String userId,
  required String entryId,
  required bool geoVerified,
});
```

### Data Layer

#### `LocationService`

Wraps `geolocator`. Responsible for permission checks and position acquisition. Never called except when the user explicitly initiates the flow.

```dart
// lib/features/diary/data/location_service.dart

enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

class LocationService {
  /// Check and request location permission.
  Future<LocationPermissionStatus> requestPermission();

  /// Acquire current position with medium accuracy.
  /// Throws [TimeoutException] after [timeout] (default 15 s).
  Future<Position> getCurrentPosition({
    Duration timeout = const Duration(seconds: 15),
  });
}
```

Implementation uses `Geolocator.requestPermission()`, `Geolocator.isLocationServiceEnabled()`, and `Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium)`.

#### `GeocodingService`

Wraps `geocoding`. Converts a `Position` to a human-readable string.

```dart
// lib/features/diary/data/geocoding_service.dart

class GeocodingService {
  /// Reverse-geocode [position] to a venue/address string.
  /// Returns null if geocoding fails or returns no results.
  Future<String?> reverseGeocode(Position position);
}
```

Implementation calls `placemarkFromCoordinates(lat, lng)` and formats the first result as `"${placemark.name}, ${placemark.locality}"`. Returns `null` on exception or empty result list.

The controller falls back to `"${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}"` when this returns `null`.

#### `MatchDao` — New Method

```dart
Future<void> updateGeoVerified(String id, bool geoVerified) =>
    (update(matchEntries)..where((t) => t.id.equals(id)))
        .write(MatchEntriesCompanion(geoVerified: Value(geoVerified)));
```

#### `DiaryLocalSource` — New Method

```dart
Future<void> updateGeoVerified(String id, bool geoVerified) {
  return _dao.updateGeoVerified(id, geoVerified);
}
```

#### `DiaryFirebaseSource` — New Method

Targeted field update — does not overwrite the full document:

```dart
Future<void> updateGeoVerified({
  required String userId,
  required String entryId,
  required bool geoVerified,
}) async {
  await _entriesRef(userId).doc(entryId).update({
    'geoVerified': geoVerified,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
```

#### `DiaryRepositoryImpl` — New Method

Follows the existing offline-first pattern:

```dart
@override
Future<Either<DiaryFailure, Unit>> updateGeoVerified({
  required String userId,
  required String entryId,
  required bool geoVerified,
}) async {
  try {
    // 1. Local write first (success boundary)
    await _local.updateGeoVerified(entryId, geoVerified);

    // 2. Remote sync or queue
    if (_isOnline()) {
      unawaited(
        _remote
            .updateGeoVerified(
              userId: userId,
              entryId: entryId,
              geoVerified: geoVerified,
            )
            .catchError((_) => _enqueueGeoVerifiedSync(
                  userId: userId,
                  entryId: entryId,
                  geoVerified: geoVerified,
                )),
      );
    } else {
      await _enqueueGeoVerifiedSync(
        userId: userId,
        entryId: entryId,
        geoVerified: geoVerified,
      );
    }

    return const Right(unit);
  } catch (e) {
    return Left(DiaryFailure.storage(e.toString()));
  }
}
```

### Presentation Layer

#### `CheckInState` — Freezed Union

```dart
@freezed
sealed class CheckInState with _$CheckInState {
  const factory CheckInState.idle() = _Idle;
  const factory CheckInState.requestingPermission() = _RequestingPermission;
  const factory CheckInState.acquiringLocation() = _AcquiringLocation;
  const factory CheckInState.geocoding() = _Geocoding;
  const factory CheckInState.locationAcquired({
    required String venueDescription,
    required double latitude,
    required double longitude,
  }) = _LocationAcquired;
  const factory CheckInState.updatingEntry() = _UpdatingEntry;
  const factory CheckInState.verified() = _Verified;
  const factory CheckInState.permissionDenied({String? message}) = _PermissionDenied;
  const factory CheckInState.permissionPermanentlyDenied({String? message}) = _PermissionPermanentlyDenied;
  const factory CheckInState.locationServiceDisabled({String? message}) = _LocationServiceDisabled;
  const factory CheckInState.acquisitionFailed({String? message}) = _AcquisitionFailed;
  const factory CheckInState.updateFailed({String? message}) = _UpdateFailed;
}
```

#### `CheckInController` — StateNotifier

```dart
// lib/features/diary/presentation/providers/check_in_providers.dart

class CheckInController extends StateNotifier<CheckInState> {
  final LocationService _locationService;
  final GeocodingService _geocodingService;
  final UpdateGeoVerified _updateGeoVerified;
  final CheckInEligibility _eligibility;
  final String _userId;

  CheckInController({...}) : super(const CheckInState.idle());

  Future<void> startCheckIn(MatchEntry entry) async {
    // Guard: eligibility check
    if (!_eligibility(entry)) {
      // No-op — UI should never call this for ineligible entries
      return;
    }

    // 1. Request permission
    state = const CheckInState.requestingPermission();
    final permission = await _locationService.requestPermission();
    switch (permission) {
      case LocationPermissionStatus.denied:
        state = const CheckInState.permissionDenied();
        return;
      case LocationPermissionStatus.permanentlyDenied:
        state = const CheckInState.permissionPermanentlyDenied();
        return;
      case LocationPermissionStatus.serviceDisabled:
        state = const CheckInState.locationServiceDisabled();
        return;
      case LocationPermissionStatus.granted:
        break;
    }

    // 2. Acquire GPS position
    state = const CheckInState.acquiringLocation();
    late Position position;
    try {
      position = await _locationService.getCurrentPosition();
    } on TimeoutException {
      state = const CheckInState.acquisitionFailed(
        message: 'GPS timed out. Move to an open area and try again.',
      );
      return;
    } catch (e) {
      state = CheckInState.acquisitionFailed(message: e.toString());
      return;
    }

    // 3. Reverse geocode
    state = const CheckInState.geocoding();
    final venue = await _geocodingService.reverseGeocode(position);
    final description = venue ??
        '${position.latitude.toStringAsFixed(5)}, '
        '${position.longitude.toStringAsFixed(5)}';

    state = CheckInState.locationAcquired(
      venueDescription: description,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<void> confirm(MatchEntry entry) async {
    // Guard: must be in locationAcquired state
    if (state is! _LocationAcquired) return;

    state = const CheckInState.updatingEntry();
    final result = await _updateGeoVerified(
      userId: _userId,
      entryId: entry.id,
    );

    result.fold(
      (failure) => state = CheckInState.updateFailed(
        message: failure.displayMessage,
      ),
      (_) => state = const CheckInState.verified(),
    );
  }

  void cancel() {
    state = const CheckInState.idle();
  }

  void reset() {
    state = const CheckInState.idle();
  }
}
```

Key invariant: `geoVerified` is only set to `true` inside `confirm()`, which is only callable when the state is `locationAcquired` — meaning the user has seen the venue description. The controller never calls `updateGeoVerified` from `startCheckIn()` or any other path.

#### `StadiumCheckInScreen`

A full-screen modal (pushed via `context.push`) that renders the current `CheckInState`:

| State | UI |
|---|---|
| `idle` / `requestingPermission` | Loading spinner, "Requesting location permission…" |
| `acquiringLocation` / `geocoding` | Loading spinner, "Finding your location…" |
| `locationAcquired` | Venue card with description, Confirm + Cancel buttons, honor-system disclaimer |
| `updatingEntry` | Loading spinner, "Saving…" |
| `verified` | Success illustration, "You're checked in!", auto-pop after 1.5 s |
| `permissionDenied` | Error icon, message, Dismiss button |
| `permissionPermanentlyDenied` | Error icon, message, "Open Settings" button |
| `locationServiceDisabled` | Error icon, message, Dismiss button |
| `acquisitionFailed` | Error icon, message, Retry + Dismiss buttons |
| `updateFailed` | Error icon, message, Retry + Dismiss buttons |

The screen pops back to `MatchDetailScreen` on cancel, dismiss, or after the verified auto-pop. The `matchEntryDetailProvider` stream will have already emitted the updated entry (with `geoVerified == true`) by the time the user returns, so the badge appears immediately without any manual refresh.

#### `MatchDetailScreen` — Check-In Button

Add a "Check In" `FilledButton.tonal` below the metadata chips, visible only when `CheckInEligibility(entry)` returns `true`:

```dart
if (CheckInEligibility()(entry))
  FilledButton.tonal(
    onPressed: () => context.push(
      Routes.stadiumCheckInPath(widget.entryId),
    ),
    child: const Row(children: [
      Icon(Icons.location_on_outlined, size: 18),
      SizedBox(width: 6),
      Text('Check In'),
    ]),
  ),
```

### Routing

#### `Routes` — New Constant and Path Builder

```dart
static const String stadiumCheckIn = '/diary/:id/check-in';

static String stadiumCheckInPath(String id) => '/diary/$id/check-in';
```

#### `AppRouter` — New GoRoute

Added as a sibling route (not a sub-route of `matchDetail`, since GoRouter's `StatefulShellRoute` does not support nested push navigation for modal flows):

```dart
GoRoute(
  path: Routes.stadiumCheckIn,
  name: 'stadiumCheckIn',
  builder: (context, state) => StadiumCheckInScreen(
    entryId: state.pathParameters['id'] ?? '',
  ),
),
```

The route sits outside the `StatefulShellRoute` branches so it renders as a full-screen page without the bottom navigation bar, consistent with `matchDetail` and `logMatch`.

---

## Data Models

### `MatchEntry` — No Schema Changes

The `geoVerified` field already exists on the domain entity, Drift table, and Firestore document. No migration is needed.

### `CheckInState` — New Freezed Union

Defined in `check_in_providers.dart` (or a dedicated `check_in_state.dart`). Not persisted — it is ephemeral UI state.

### Sync Queue Payload for `updateGeoVerified`

When offline, the repository enqueues a sync operation using the existing `SyncQueue` table:

```json
{
  "operation": "updateGeoVerified",
  "collection": "match_entries",
  "documentId": "<entryId>",
  "payload": "{\"userId\": \"<userId>\", \"geoVerified\": true}"
}
```

The existing sync worker will need a handler for the `"updateGeoVerified"` operation type that calls `DiaryFirebaseSource.updateGeoVerified()`.

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

The eligibility predicate (`CheckInEligibility`) is a pure function with a well-defined input space and clear universal invariants. It is the ideal candidate for property-based testing with `kiri_check`. The controller's `geoVerified`-mutation invariant is also universally quantifiable.

**Property Reflection:**

Before writing properties, I consolidate the prework findings:

- Requirements 1.1, 1.2, 10.4 all express the same predicate: non-stadium entries are ineligible. These collapse into one property.
- Requirements 1.5, 1.6, 10.5 all express the same predicate: non-today entries are ineligible. These collapse into one property.
- Requirement 10.6 is the positive case: today's unverified stadium entries are eligible. This is a distinct property.
- Requirement 1.3 (already-verified entries are ineligible) is a distinct property.
- Requirement 5.7 (geoVerified never set without confirmation) is a controller-level invariant property.
- Requirement 8.5 (idempotency of updateGeoVerified) is a repository-level property.

After reflection, Properties 1 and 2 together with Property 3 fully cover the eligibility predicate. There is no redundancy between them — each tests a different dimension of the three-part conjunction.

---

### Property 1: Non-stadium entries are never eligible

*For any* `MatchEntry` where `watchType != 'stadium'`, regardless of `geoVerified` value, `matchDate`, or any other field, `CheckInEligibility()(entry)` SHALL return `false`.

**Validates: Requirements 1.1, 1.2, 10.4**

---

### Property 2: Non-today entries are never eligible

*For any* `MatchEntry` where `watchType == 'stadium'` and `geoVerified == false` but `createdAt` does not fall on today's calendar date (in device local timezone), `CheckInEligibility()(entry)` SHALL return `false`.

**Validates: Requirements 1.5, 1.6, 10.5**

---

### Property 3: Already-verified entries are never eligible

*For any* `MatchEntry` where `watchType == 'stadium'` and `geoVerified == true`, regardless of `createdAt`, `CheckInEligibility()(entry)` SHALL return `false`.

**Validates: Requirements 1.3**

---

### Property 4: Eligible entries satisfy all three conditions simultaneously

*For any* `MatchEntry` where `watchType == 'stadium'`, `geoVerified == false`, and `createdAt` falls on today's calendar date, `CheckInEligibility()(entry)` SHALL return `true`.

**Validates: Requirements 1.4, 10.6**

---

### Property 5: geoVerified is never set without explicit confirmation

*For any* sequence of `CheckInController` events that does not include a `confirm()` call, the `UpdateGeoVerified` use case SHALL never be invoked, and no `MatchEntry` SHALL have its `geoVerified` field changed to `true`.

**Validates: Requirements 5.7, 4.3**

---

## Error Handling

### Permission Errors

| Scenario | State | User Action |
|---|---|---|
| Permission denied (one-time) | `permissionDenied` | Dismiss — can retry by tapping "Check In" again |
| Permission permanently denied | `permissionPermanentlyDenied` | "Open Settings" button → `Geolocator.openAppSettings()` |
| Location services off | `locationServiceDisabled` | Dismiss — user must enable in device settings |

### GPS / Geocoding Errors

| Scenario | State | User Action |
|---|---|---|
| 15 s timeout | `acquisitionFailed` | Retry or Dismiss |
| Platform exception | `acquisitionFailed` | Retry or Dismiss |
| Geocoding failure | Fallback to coordinates in `locationAcquired` | No error shown — coordinates are displayed instead |

### Repository Errors

| Scenario | State | User Action |
|---|---|---|
| Local Drift write fails | `updateFailed` | Retry or Dismiss — entry is NOT modified |
| Remote sync fails (online) | Enqueued silently | No user-visible error — offline-first contract |
| Remote sync fails (offline) | Enqueued silently | No user-visible error — offline-first contract |

### Ineligibility Guards

The "Check In" button is never rendered for ineligible entries, so the controller's eligibility guard is a defense-in-depth measure. If `startCheckIn()` is called with an ineligible entry (e.g., due to a race condition where the date changes at midnight), the controller silently returns to `idle` without requesting location permission.

---

## Testing Strategy

### Unit Tests — `CheckInController`

Cover every state transition in the state machine using `mocktail` mocks for `LocationService`, `GeocodingService`, and `UpdateGeoVerified`:

1. **Happy path**: permission granted → position acquired → geocoding succeeds → `locationAcquired` → confirm → `verified`
2. **Permission denied**: `permissionDenied` state, `UpdateGeoVerified` never called
3. **Permission permanently denied**: `permissionPermanentlyDenied` state
4. **Location service disabled**: `locationServiceDisabled` state
5. **GPS timeout**: `acquisitionFailed` state after 15 s mock timeout
6. **Geocoding failure fallback**: `locationAcquired` with coordinate string, not error state
7. **User cancels at confirmation**: state returns to `idle`, `UpdateGeoVerified` never called
8. **Local write failure**: `updateFailed` state, `geoVerified` not mutated
9. **Ineligible entry (non-stadium)**: `startCheckIn()` is a no-op, no permission request
10. **Ineligible entry (non-today)**: `startCheckIn()` is a no-op, no permission request

### Unit Tests — `DiaryRepositoryImpl.updateGeoVerified`

1. Online path: local write → remote update called
2. Offline path: local write → sync queue entry created
3. Remote failure: local write succeeds → sync queue entry created (no error returned)
4. Local write failure: `Left(DiaryFailure.storage(...))` returned

### Widget Tests

1. `MatchDetailScreen` shows "Check In" button for eligible entry
2. `MatchDetailScreen` hides "Check In" button for non-stadium entry
3. `MatchDetailScreen` hides "Check In" button for already-verified entry
4. `MatchDetailScreen` hides "Check In" button for past-date entry
5. `MatchDetailScreen` shows `_MetaChip` with `highlight: true` when `geoVerified == true`
6. `StadiumCheckInScreen` shows venue description and Confirm/Cancel in `locationAcquired` state
7. `StadiumCheckInScreen` shows "Open Settings" button in `permissionPermanentlyDenied` state

### Property-Based Tests — `kiri_check`

The property tests use `kiri_check`'s `Arbitrary` generators to produce random `MatchEntry` instances. Each test runs a minimum of 100 iterations.

**Tag format**: `// Feature: stadium-check-in, Property {N}: {property_text}`

#### Property 1 Test

```dart
// Feature: stadium-check-in, Property 1: Non-stadium entries are never eligible
test('non-stadium entries are never eligible', () {
  forAll(
    matchEntryArb.map((e) => e.copyWith(
      watchType: arbitrary.oneOf(['tv', 'streaming', 'radio']).sample(),
    )),
    (entry) {
      expect(CheckInEligibility()(entry), isFalse);
    },
  );
});
```

#### Property 2 Test

```dart
// Feature: stadium-check-in, Property 2: Non-today entries are never eligible
test('non-today stadium entries are never eligible', () {
  final today = DateTime.now();
  forAll(
    matchEntryArb.map((e) => e.copyWith(
      watchType: 'stadium',
      geoVerified: false,
      createdAt: arbitrary.dateTime.where((d) =>
        !(d.year == today.year && d.month == today.month && d.day == today.day)
      ).sample(),
    )),
    (entry) {
      expect(CheckInEligibility()(entry), isFalse);
    },
  );
});
```

#### Property 3 Test

```dart
// Feature: stadium-check-in, Property 3: Already-verified entries are never eligible
test('already-verified stadium entries are never eligible', () {
  forAll(
    matchEntryArb.map((e) => e.copyWith(
      watchType: 'stadium',
      geoVerified: true,
    )),
    (entry) {
      expect(CheckInEligibility()(entry), isFalse);
    },
  );
});
```

#### Property 4 Test

```dart
// Feature: stadium-check-in, Property 4: Eligible entries satisfy all three conditions
test('today unverified stadium entries are eligible', () {
  final today = DateTime.now();
  forAll(
    matchEntryArb.map((e) => e.copyWith(
      watchType: 'stadium',
      geoVerified: false,
      createdAt: DateTime(today.year, today.month, today.day,
        arbitrary.integer(0, 23).sample(),
        arbitrary.integer(0, 59).sample(),
      ),
    )),
    (entry) {
      expect(CheckInEligibility()(entry), isTrue);
    },
  );
});
```

#### Property 5 Test

```dart
// Feature: stadium-check-in, Property 5: geoVerified never set without confirmation
test('geoVerified is never set without explicit confirmation', () async {
  forAll(
    arbitrary.list(checkInEventArb.where((e) => e != CheckInEvent.confirm)),
    (events) async {
      final controller = CheckInController(...mockDeps...);
      for (final event in events) {
        await applyEvent(controller, event);
      }
      verifyNever(() => mockUpdateGeoVerified(any(), any()));
    },
  );
});
```

### Integration Tests

1. Full check-in flow on a real device/emulator: permission → GPS → geocode → confirm → Firestore field updated
2. Offline check-in: confirm → local Drift row updated → sync queue entry created → sync worker replays → Firestore updated

### Dual Testing Rationale

Unit tests cover specific state transitions and error paths with deterministic mocks. Property tests verify the eligibility predicate's universal correctness across the full input space — catching edge cases like entries created at 23:59 on the previous day, entries with unusual `watchType` strings, or entries with `geoVerified` in unexpected states. Together they provide comprehensive coverage without redundancy.
