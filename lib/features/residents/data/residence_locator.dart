import 'package:geolocator/geolocator.dart';

import 'residence_data.dart';

class ResidenceLocator {
  const ResidenceLocator._();

  static Future<Residence?> detectNearest() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    Residence? nearest;
    var nearestDistance = double.infinity;
    for (final residence in availableResidences) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        residence.latitude,
        residence.longitude,
      );
      if (distance <= residence.radius && distance < nearestDistance) {
        nearest = residence;
        nearestDistance = distance;
      }
    }
    return nearest;
  }
}
