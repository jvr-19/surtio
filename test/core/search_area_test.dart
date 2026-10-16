import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:surtio/core/location/location_service.dart';
import 'package:surtio/core/location/search_area.dart';

class UnavailableLocation extends LocationService {
  int calls = 0;
  @override
  Future<Position> getCurrentPosition() async {
    calls++;
    throw const PermissionDeniedException('Denied');
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('manual area and radius survive a new controller', () async {
    final first = SearchAreaController(locationService: UnavailableLocation());
    first.select(
      const SearchArea(latitude: 40.4, longitude: -3.7, label: 'Madrid'),
    );
    first.selectRadius(50);
    await first.pendingPersistence;
    final location = UnavailableLocation();
    final restored = SearchAreaController(locationService: location);
    await restored.initialize();
    expect(restored.area.label, 'Madrid');
    expect(restored.radiusKm, 50);
    expect(location.calls, 0);
  });

  test(
    'device position is never persisted and replaces a saved manual area',
    () async {
      final controller = SearchAreaController(
        locationService: UnavailableLocation(),
      );
      controller.select(
        const SearchArea(latitude: 40.4, longitude: -3.7, label: 'Madrid'),
      );
      controller.select(
        const SearchArea(
          latitude: 41,
          longitude: -4,
          label: 'Tu ubicación',
          isDevice: true,
        ),
      );
      await controller.pendingPersistence;
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('manual_search_area'), isNull);
    },
  );

  test(
    'corrupt stored area falls back and invalid radius is ignored',
    () async {
      SharedPreferences.setMockInitialValues({
        'manual_search_area': '{broken',
        'search_radius_km': 900.0,
      });
      final location = UnavailableLocation();
      final controller = SearchAreaController(locationService: location);
      await controller.initialize();
      expect(controller.radiusKm, 20);
      expect(controller.area.isDevice, isFalse);
      expect(location.calls, 0);
      controller.selectRadius(-5);
      expect(controller.radiusKm, 20);
    },
  );

  test('a selection made while preferences load is not overwritten', () async {
    SharedPreferences.setMockInitialValues({
      'manual_search_area':
          '{"latitude":40.4,"longitude":-3.7,"label":"Madrid"}',
      'search_radius_km': 50.0,
    });
    final controller = SearchAreaController(
      locationService: UnavailableLocation(),
    );
    final loading = controller.initialize();
    controller.select(
      const SearchArea(latitude: 28.1, longitude: -15.4, label: 'Las Palmas'),
    );
    controller.selectRadius(10);
    await loading;
    await controller.pendingPersistence;
    expect(controller.area.label, 'Las Palmas');
    expect(controller.radiusKm, 10);
  });

  test(
    'startup does not request location and explicit denial keeps browsing usable',
    () async {
      final location = UnavailableLocation();
      final areas = SearchAreaController(locationService: location);
      await Future.wait([areas.initialize(), areas.initialize()]);
      expect(location.calls, 0);
      expect(areas.area.isDevice, isFalse);
      expect(areas.area.label, 'Las Palmas de Gran Canaria');
      await expectLater(
        areas.useDeviceLocation(),
        throwsA(isA<PermissionDeniedException>()),
      );
      expect(location.calls, 1);
      expect(areas.area.isDevice, isFalse);
      areas.select(
        const SearchArea(latitude: 40.4, longitude: -3.7, label: 'Madrid'),
      );
      expect(areas.area.label, 'Madrid');
      expect(areas.area.latitude, 40.4);
    },
  );
}
