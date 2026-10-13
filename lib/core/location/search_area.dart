import 'package:flutter/foundation.dart';

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

  Future<void> initialize() {
    if (_chosen) return Future.value();
    return _initializing ??= _locate();
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
