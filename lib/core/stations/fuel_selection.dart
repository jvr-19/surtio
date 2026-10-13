import 'package:flutter/foundation.dart';

import '../../features/map/data/models/fuel_station.dart';
import '../../features/vehicle/data/repositories/vehicle_profile_repository.dart';

class FuelSelection extends ValueNotifier<FuelType> {
  FuelSelection({VehicleProfileRepository? repository})
    : _repository = repository ?? SharedPreferencesVehicleProfileRepository(),
      super(FuelType.gasoline95);

  static final instance = FuelSelection();
  final VehicleProfileRepository _repository;
  Future<void>? _loading;
  bool _selected = false;

  Future<void> initialize() => _loading ??= _loadVehicle();

  Future<void> _loadVehicle() async {
    try {
      final profile = await _repository.load();
      if (!_selected && profile != null) value = profile.fuelType;
    } catch (_) {
      // A storage failure must not prevent browsing stations.
    }
  }

  void select(FuelType fuel) {
    _selected = true;
    value = fuel;
  }
}
