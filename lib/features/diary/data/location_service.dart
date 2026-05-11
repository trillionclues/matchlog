// LocationService wraps geolocator package.

// Responsibilities:
//   - Check and request location permission
//   - Acquire the current GPS position with medium accuracy
//   - Apply a 15-second timeout to GPS acquisition

// This service is only called when the user explicitly initiates the
// Stadium Check-In flow. It never requests location in the background.

library;

import 'package:geolocator/geolocator.dart';

// Normalised permission result returned by [LocationService.requestPermission].
enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

class LocationService {
  const LocationService();

  // Checks whether location services are enabled and requests permission if needed.
  Future<LocationPermissionStatus> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse =>
        LocationPermissionStatus.granted,
      LocationPermission.deniedForever =>
        LocationPermissionStatus.permanentlyDenied,
      _ => LocationPermissionStatus.denied,
    };
  }

  // Acquires the current GPS position with medium accuracy.
  Future<Position> getCurrentPosition({
    Duration timeout = const Duration(seconds: 15),
  }) {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    ).timeout(timeout);
  }
}
