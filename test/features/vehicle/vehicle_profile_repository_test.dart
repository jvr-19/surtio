import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surtio/features/map/data/models/fuel_station.dart';
import 'package:surtio/features/vehicle/data/models/vehicle_profile.dart';
import 'package:surtio/features/vehicle/data/repositories/vehicle_profile_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns null when no vehicle has been saved', () async {
    final repository = SharedPreferencesVehicleProfileRepository();

    expect(await repository.load(), isNull);
  });

  test('persists and loads the vehicle profile', () async {
    final repository = SharedPreferencesVehicleProfileRepository();
    const profile = VehicleProfile(
      name: 'Seat León',
      variant: '1.5 TSI',
      fuelType: FuelType.gasoline95,
      averageConsumption: 6.1,
      tankCapacity: 50,
    );

    await repository.save(profile);
    final loaded = await repository.load();

    expect(loaded, isNotNull);
    expect(loaded!.name, 'Seat León');
    expect(loaded.variant, '1.5 TSI');
    expect(loaded.fuelType, FuelType.gasoline95);
    expect(loaded.averageConsumption, 6.1);
    expect(loaded.tankCapacity, 50);
  });
}
