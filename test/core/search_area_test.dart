import 'package:flutter_test/flutter_test.dart';
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
  test('denied location leaves an explicit usable manual area', () async {
    final location = UnavailableLocation();
    final areas = SearchAreaController(locationService: location);
    await Future.wait([areas.initialize(), areas.initialize()]);
    expect(location.calls, 1);
    expect(areas.area.isDevice, isFalse);
    expect(areas.area.label, 'Las Palmas de Gran Canaria');
    areas.select(
      const SearchArea(latitude: 40.4, longitude: -3.7, label: 'Madrid'),
    );
    expect(areas.area.label, 'Madrid');
    expect(areas.area.latitude, 40.4);
  });
}
