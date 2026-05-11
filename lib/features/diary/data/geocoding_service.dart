// GeocodingService wraps the geocoding package.

// Converts a GPS Position into a human-readable venue/address string.

library;

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class GeocodingService {
  const GeocodingService();

  // Returns `null` if geocoding fails or returns no results.
  // The caller is responsible for providing a coordinate fallback.
  Future<String?> reverseGeocode(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return null;

      final placemark = placemarks.first;
      
      final parts = <String>[
        if (placemark.name != null && placemark.name!.isNotEmpty)
          placemark.name!,
        if (placemark.locality != null && placemark.locality!.isNotEmpty)
          placemark.locality!,
      ];

      if (parts.isEmpty) return null;
      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}
