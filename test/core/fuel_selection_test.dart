import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:surtio/core/stations/fuel_selection.dart';
import 'package:surtio/features/map/data/models/fuel_station.dart';
import 'package:surtio/features/vehicle/data/models/vehicle_profile.dart';
import 'package:surtio/features/vehicle/data/repositories/vehicle_profile_repository.dart';

class PendingVehicleRepository implements VehicleProfileRepository {
  final result = Completer<VehicleProfile?>();
  @override
  Future<VehicleProfile?> load() => result.future;
  @override
  Future<void> save(VehicleProfile profile) async {}
}

const vehicle = VehicleProfile(
  name: 'Mi coche',
  fuelType: FuelType.diesel,
  averageConsumption: 6,
  tankCapacity: 50,
);

void main() {
  test('saved vehicle sets the initial common fuel filter', () async {
    final repository = PendingVehicleRepository();
    final selection = FuelSelection(repository: repository);
    final initialized = selection.initialize();
    repository.result.complete(vehicle);
    await initialized;
    expect(selection.value, FuelType.diesel);
  });

  test(
    'loading a vehicle never overwrites a filter the user just selected',
    () async {
      final repository = PendingVehicleRepository();
      final selection = FuelSelection(repository: repository);
      final initialized = selection.initialize();
      selection.select(FuelType.lpg);
      repository.result.complete(vehicle);
      await initialized;
      expect(selection.value, FuelType.lpg);
    },
  );
}
