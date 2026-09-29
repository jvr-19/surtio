class FuelStation {
  const FuelStation({
    required this.id,
    required this.name,
    required this.address,
    required this.municipality,
    required this.municipalityId,
    required this.province,
    required this.latitude,
    required this.longitude,
    required this.schedule,
    this.gasoline95Price,
    this.gasoline98Price,
    this.dieselPrice,
    this.premiumDieselPrice,
    this.lpgPrice,
  });

  final String id;
  final String name;
  final String address;
  final String municipality;
  final String municipalityId;
  final String province;
  final double latitude;
  final double longitude;
  final String schedule;

  final double? gasoline95Price;
  final double? gasoline98Price;
  final double? dieselPrice;
  final double? premiumDieselPrice;
  final double? lpgPrice;

  factory FuelStation.fromJson(Map<String, dynamic> json) {
    return FuelStation(
      id: json['IDEESS']?.toString() ?? '',
      name: json['Rótulo']?.toString() ?? '',
      address: json['Dirección']?.toString() ?? '',
      municipality: json['Municipio']?.toString() ?? '',
      municipalityId: json['IDMunicipio']?.toString() ?? '',
      province: json['Provincia']?.toString() ?? '',
      latitude: _parseDouble(json['Latitud']) ?? 0,
      longitude: _parseDouble(json['Longitud (WGS84)']) ?? 0,
      schedule: json['Horario']?.toString().trim() ?? '',
      gasoline95Price: _parseDouble(json['Precio Gasolina 95 E5']),
      gasoline98Price: _parseDouble(json['Precio Gasolina 98 E5']),
      dieselPrice: _parseDouble(json['Precio Gasoleo A']),
      premiumDieselPrice: _parseDouble(json['Precio Gasoleo Premium']),
      lpgPrice: _parseDouble(json['Precio Gases licuados del petróleo']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return double.tryParse(text.replaceAll(',', '.'));
  }

  double? priceFor(FuelType fuelType) {
    return switch (fuelType) {
      FuelType.gasoline95 => gasoline95Price,
      FuelType.gasoline98 => gasoline98Price,
      FuelType.diesel => dieselPrice,
      FuelType.premiumDiesel => premiumDieselPrice,
      FuelType.lpg => lpgPrice,
    };
  }
}

enum FuelType { gasoline95, gasoline98, diesel, premiumDiesel, lpg }

extension FuelTypeX on FuelType {
  String get label {
    return switch (this) {
      FuelType.gasoline95 => '95',
      FuelType.gasoline98 => '98',
      FuelType.diesel => 'Diésel',
      FuelType.premiumDiesel => 'Diésel+',
      FuelType.lpg => 'GLP',
    };
  }

  String get markerLabel {
    return switch (this) {
      FuelType.gasoline95 => '95',
      FuelType.gasoline98 => '98',
      FuelType.diesel => 'D',
      FuelType.premiumDiesel => 'D+',
      FuelType.lpg => 'GLP',
    };
  }

  String get fullName {
    return switch (this) {
      FuelType.gasoline95 => 'Gasolina 95',
      FuelType.gasoline98 => 'Gasolina 98',
      FuelType.diesel => 'Diésel',
      FuelType.premiumDiesel => 'Diésel+',
      FuelType.lpg => 'GLP',
    };
  }
}
