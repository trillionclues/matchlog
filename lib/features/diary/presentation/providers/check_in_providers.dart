// Stadium Check-In state, controller, and Riverpod providers.

// CheckInState is a Freezed sealed union covering every step of the
// check-in flow. CheckInController is a StateNotifier that drives the state

library;

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:matchlog/core/utils/app_logger.dart';

import '../../data/geocoding_service.dart';
import '../../data/location_service.dart';
import '../../domain/entities/match_entry.dart';
import '../../domain/failures/diary_failure.dart';
import '../../domain/usecases/check_in_eligibility.dart';
import '../../domain/usecases/update_geo_verified.dart';
import 'diary_providers.dart';

part 'check_in_providers.freezed.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

@freezed
sealed class CheckInState with _$CheckInState {
  const factory CheckInState.idle() = _Idle;

  // await OS permission dialog to resolve.
  const factory CheckInState.requestingPermission() = _RequestingPermission;

  // Permission granted; waiting for GPS fix.
  const factory CheckInState.acquiringLocation() = _AcquiringLocation;

  // GPS fix obtained; waiting for reverse geocoding to complete.
  const factory CheckInState.geocoding() = _Geocoding;

  // Location resolved — user must confirm before geoVerified is written.
  const factory CheckInState.locationAcquired({
    required String venueDescription,
    required double latitude,
    required double longitude,
  }) = _LocationAcquired;

  const factory CheckInState.updatingEntry() = _UpdatingEntry;

  // Local write succeeded — entry is now geo-verified.
  const factory CheckInState.verified() = _Verified;

  // User denied location permission (can retry by tapping Check In again).
  const factory CheckInState.permissionDenied({String? message}) =
      _PermissionDenied;

  // Permission permanently denied — user must open device settings.
  const factory CheckInState.permissionPermanentlyDenied({String? message}) =
      _PermissionPermanentlyDenied;

  const factory CheckInState.locationServiceDisabled({String? message}) =
      _LocationServiceDisabled;

  const factory CheckInState.acquisitionFailed({String? message}) =
      _AcquisitionFailed;

  /// Local Drift write failed — entry is NOT modified.
  const factory CheckInState.updateFailed({String? message}) = _UpdateFailed;
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class CheckInController extends StateNotifier<CheckInState> {
  final LocationService _locationService;
  final GeocodingService _geocodingService;
  final UpdateGeoVerified _updateGeoVerified;
  final CheckInEligibility _eligibility;
  final String _userId;

  CheckInController({
    required LocationService locationService,
    required GeocodingService geocodingService,
    required UpdateGeoVerified updateGeoVerified,
    required CheckInEligibility eligibility,
    required String userId,
  })  : _locationService = locationService,
        _geocodingService = geocodingService,
        _updateGeoVerified = updateGeoVerified,
        _eligibility = eligibility,
        _userId = userId,
        super(const CheckInState.idle());

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------
  Future<void> startCheckIn(MatchEntry entry) async {
    // Eligibility guard — defense-in-depth; the UI should never call this
    // for ineligible entries, but we protect against race conditions.
    if (!_eligibility(entry)) return;

    // 1. Request location permission.
    state = const CheckInState.requestingPermission();
    final permission = await _locationService.requestPermission();

    switch (permission) {
      case LocationPermissionStatus.denied:
        state = const CheckInState.permissionDenied(
          message: 'Location permission was denied. '
              'Tap "Check In" again to retry.',
        );
        return;
      case LocationPermissionStatus.permanentlyDenied:
        state = const CheckInState.permissionPermanentlyDenied(
          message: 'Location permission is permanently denied. '
              'Open Settings to allow location access for MatchLog.',
        );
        return;
      case LocationPermissionStatus.serviceDisabled:
        state = const CheckInState.locationServiceDisabled(
          message: 'Location services are disabled on this device. '
              'Enable them in Settings to check in.',
        );
        return;
      case LocationPermissionStatus.granted:
        break;
    }

    // 2. Acquire GPS position.
    state = const CheckInState.acquiringLocation();
    late Position position;
    try {
      position = await _locationService.getCurrentPosition();
    } on TimeoutException {
      state = const CheckInState.acquisitionFailed(
        message: 'GPS timed out after 15 seconds. '
            'Move to an open area and try again.',
      );
      return;
    } catch (e) {
      state = CheckInState.acquisitionFailed(
        message: 'Could not get your location: ${e.toString()}',
      );
      return;
    }

    // 3. Reverse geocode to a human-readable venue description.
    state = const CheckInState.geocoding();
    final venue = await _geocodingService.reverseGeocode(position);
    AppLogger.log(
      'Raw position: ${position.latitude}, ${position.longitude}',
      tag: 'Geocoding',
    );

    // Fall back to raw coordinates if geocoding returns nothing.
    final description = venue ??
        '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}';

    state = CheckInState.locationAcquired(
      venueDescription: description,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  // Confirms the detected location and writes geoVerified = true.
  // Only callable when the state is [_LocationAcquired]. Any other state
  // is a no-op — guard that ensures geoVerified is never set without explicit user confirmation.
  Future<void> confirm(MatchEntry entry) async {
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

  void cancel() => state = const CheckInState.idle();

  void reset() => state = const CheckInState.idle();
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final checkInEligibilityProvider = Provider<CheckInEligibility>(
  (_) => const CheckInEligibility(),
);

final locationServiceProvider = Provider<LocationService>(
  (_) => const LocationService(),
);

final geocodingServiceProvider = Provider<GeocodingService>(
  (_) => const GeocodingService(),
);

final updateGeoVerifiedUseCaseProvider = Provider<UpdateGeoVerified>((ref) {
  return UpdateGeoVerified(ref.watch(diaryRepositoryProvider));
});

final checkInControllerProvider = StateNotifierProvider.autoDispose
    .family<CheckInController, CheckInState, String>(
  (ref, userId) => CheckInController(
    locationService: ref.watch(locationServiceProvider),
    geocodingService: ref.watch(geocodingServiceProvider),
    updateGeoVerified: ref.watch(updateGeoVerifiedUseCaseProvider),
    eligibility: ref.watch(checkInEligibilityProvider),
    userId: userId,
  ),
);
