import 'package:flutter_test/flutter_test.dart';
import 'package:surtio/features/map/data/models/fuel_station.dart';
import 'package:surtio/features/vehicle/data/models/vehicle_profile.dart';

void main() {
  test('calculates theoretical range from capacity and consumption', () {
    const profile = VehicleProfile(
      name: 'Coche de prueba',
      fuelType: FuelType.gasoline95,
      averageConsumption: 6.1,
      tankCapacity: 50,
    );

    expect(profile.theoreticalRangeKm, closeTo(819.67, 0.01));
  });

  test('serializes and restores all vehicle fields', () {
    const profile = VehicleProfile(
      name: 'Seat León',
      variant: '1.5 TSI',
      fuelType: FuelType.gasoline95,
      averageConsumption: 6.1,
      tankCapacity: 50,
    );

    final restored = VehicleProfile.fromJson(profile.toJson());

    expect(restored.name, profile.name);
    expect(restored.variant, profile.variant);
    expect(restored.fuelType, profile.fuelType);
    expect(restored.averageConsumption, profile.averageConsumption);
    expect(restored.tankCapacity, profile.tankCapacity);
  });
}
