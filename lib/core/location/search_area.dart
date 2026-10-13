import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'location_service.dart';

class SearchArea {
  const SearchArea({
    required this.latitude,
    required this.longitude,
    required this.label,
    this.isDevice = false,
  });
  final double latitude;
  final double longitude;
  final String label;
  final bool isDevice;
}

class SearchAreaController extends ChangeNotifier {
  SearchAreaController({LocationService? locationService})
    : _locationService = locationService ?? const LocationService();
  final LocationService _locationService;
  static final instance = SearchAreaController();
  SearchArea area = const SearchArea(
    latitude: 28.1,
    longitude: -15.4167,
    label: 'Las Palmas de Gran Canaria',
  );
  Future<void>? _initializing;
  bool _chosen = false;
  bool _radiusChosen = false;
  double radiusKm = 20;
  static const radiusOptions = [5.0, 10.0, 20.0, 50.0];
  Future<void> _saving = Future.value();
  Future<void> get pendingPersistence => _saving;

  Future<void> initialize() => _initializing ??= _restore();

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRadius = prefs.getDouble('search_radius_km');
      if (!_radiusChosen && radiusOptions.contains(savedRadius)) {
        radiusKm = savedRadius!;
      }
      final raw = prefs.getString('manual_search_area');
      if (!_chosen && raw != null) {
        final saved = jsonDecode(raw);
        if (saved is Map<String, dynamic>) {
          final lat = saved['latitude'];
          final lon = saved['longitude'];
          final label = saved['label'];
          if (lat is num &&
              lon is num &&
              label is String &&
              label.trim().isNotEmpty &&
              lat.isFinite &&
              lon.isFinite &&
              lat >= -90 &&
              lat <= 90 &&
              lon >= -180 &&
              lon <= 180) {
            area = SearchArea(
              latitude: lat.toDouble(),
              longitude: lon.toDouble(),
              label: label,
            );
            _chosen = true;
          }
        }
      }
      notifyListeners();
    } catch (_) {
      // Corrupt or unavailable preferences must not block browsing.
    }
    if (!_chosen) await _locate();
  }

  void selectRadius(double radius) {
    if (!radiusOptions.contains(radius)) return;
    _radiusChosen = true;
    if (radiusKm == radius) return;
    radiusKm = radius;
    notifyListeners();
    _persist();
  }

  void _persist() {
    final selectedArea = area;
    final selectedRadius = radiusKm;
    final saveManualArea = _chosen && !selectedArea.isDevice;
    _saving = _saving.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('search_radius_km', selectedRadius);
        if (!saveManualArea) {
          await prefs.remove('manual_search_area');
        } else {
          await prefs.setString(
            'manual_search_area',
            jsonEncode({
              'latitude': selectedArea.latitude,
              'longitude': selectedArea.longitude,
              'label': selectedArea.label,
            }),
          );
        }
      } catch (_) {
        // Keep the current selection usable when storage is unavailable.
      }
    });
  }

  Future<void> _locate() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (!_chosen) {
        area = SearchArea(
          latitude: position.latitude,
          longitude: position.longitude,
          label: 'Tu ubicación',
          isDevice: true,
        );
        notifyListeners();
      }
    } catch (_) {
      // Keep the explicitly labelled manual area when location is unavailable.
    }
  }

  void select(SearchArea value) {
    _chosen = true;
    area = value;
    notifyListeners();
    _persist();
  }

  Future<void> useDeviceLocation() async {
    final position = await _locationService.getCurrentPosition();
    select(
      SearchArea(
        latitude: position.latitude,
        longitude: position.longitude,
        label: 'Tu ubicación',
        isDevice: true,
      ),
    );
  }
}
