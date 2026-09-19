import 'package:geolocator/geolocator.dart';

import '../../data/models/fuel_station.dart';

class StationDistanceService {
  const StationDistanceService();

  List<FuelStation> nearbyStations({
    required List<FuelStation> stations,
    required double latitude,
    required double longitude,
    double radiusKm = 20,
  }) {
    final nearby = stations.where((station) {
      final distanceMeters = Geolocator.distanceBetween(
        latitude,
        longitude,
        station.latitude,
        station.longitude,
      );

      return distanceMeters <= radiusKm * 1000;
    }).toList();

    nearby.sort((a, b) {
      final distanceA = Geolocator.distanceBetween(
        latitude,
        longitude,
        a.latitude,
        a.longitude,
      );

      final distanceB = Geolocator.distanceBetween(
        latitude,
        longitude,
        b.latitude,
        b.longitude,
      );

      return distanceA.compareTo(distanceB);
    });

    return nearby;
  }
}
