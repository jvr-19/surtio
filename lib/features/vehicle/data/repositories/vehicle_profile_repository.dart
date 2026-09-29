import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle_profile.dart';

abstract interface class VehicleProfileRepository {
  Future<VehicleProfile?> load();

  Future<void> save(VehicleProfile profile);
}

class SharedPreferencesVehicleProfileRepository
    implements VehicleProfileRepository {
  static const _profileKey = 'vehicle_profile_v1';

  @override
  Future<VehicleProfile?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawProfile = preferences.getString(_profileKey);
    if (rawProfile == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawProfile);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return VehicleProfile.fromJson(decoded);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> save(VehicleProfile profile) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _profileKey,
      jsonEncode(profile.toJson()),
    );
    if (!saved) {
      throw StateError('No se pudo guardar el perfil del vehículo');
    }
  }
}
