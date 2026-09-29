import '../../../map/data/models/fuel_station.dart';

class VehicleProfile {
  const VehicleProfile({
    required this.name,
    required this.fuelType,
    required this.averageConsumption,
    required this.tankCapacity,
    this.variant,
  });

  final String name;
  final String? variant;
  final FuelType fuelType;
  final double averageConsumption;
  final double tankCapacity;

  double get theoreticalRangeKm => tankCapacity / averageConsumption * 100;

  Map<String, Object?> toJson() => {
    'name': name,
    'variant': variant,
    'fuelType': fuelType.name,
    'averageConsumption': averageConsumption,
    'tankCapacity': tankCapacity,
  };

  factory VehicleProfile.fromJson(Map<String, dynamic> json) {
    final fuelName = json['fuelType'] as String?;
    final fuelType = FuelType.values.firstWhere(
      (fuel) => fuel.name == fuelName,
      orElse: () => FuelType.gasoline95,
    );

    return VehicleProfile(
      name: json['name'] as String,
      variant: json['variant'] as String?,
      fuelType: fuelType,
      averageConsumption: (json['averageConsumption'] as num).toDouble(),
      tankCapacity: (json['tankCapacity'] as num).toDouble(),
    );
  }
}
