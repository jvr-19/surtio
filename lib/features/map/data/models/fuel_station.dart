class FuelStation {
  const FuelStation({
    required this.id,
    required this.name,
    required this.address,
    required this.municipality,
    required this.province,
    required this.latitude,
    required this.longitude,
    required this.gasoline95Price,
  });

  final String id;
  final String name;
  final String address;
  final String municipality;
  final String province;
  final double latitude;
  final double longitude;
  final double? gasoline95Price;

  factory FuelStation.fromJson(Map<String, dynamic> json) {
    return FuelStation(
      id: json['IDEESS']?.toString() ?? '',
      name: json['Rótulo']?.toString() ?? '',
      address: json['Dirección']?.toString() ?? '',
      municipality: json['Municipio']?.toString() ?? '',
      province: json['Provincia']?.toString() ?? '',
      latitude: _parseSpanishDouble(json['Latitud']),
      longitude: _parseSpanishDouble(json['Longitud (WGS84)']),
      gasoline95Price: _parseNullableSpanishDouble(
        json['Precio Gasolina 95 E5'],
      ),
    );
  }

  static double _parseSpanishDouble(dynamic value) {
    return double.parse(value.toString().trim().replaceAll(',', '.'));
  }

  static double? _parseNullableSpanishDouble(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) return null;

    return double.tryParse(text.replaceAll(',', '.'));
  }
}
