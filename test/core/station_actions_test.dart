import 'package:flutter_test/flutter_test.dart';
import 'package:surtio/core/stations/station_actions.dart';
import 'package:surtio/features/map/data/models/fuel_station.dart';

const station = FuelStation(
  id: '1',
  name: 'Estación & Norte',
  address: 'Calle 1',
  municipality: 'Arucas',
  municipalityId: '1',
  province: 'Las Palmas',
  latitude: 28.1,
  longitude: -15.4,
  schedule: '',
  gasoline95Price: 1.234,
);

void main() {
  test('route sends the station coordinates, not the user location', () {
    final uri = StationActions.routeUri(station);
    expect(uri.scheme, 'https');
    expect(uri.queryParameters['destination'], '28.1,-15.4');
    expect(uri.queryParameters['travelmode'], 'driving');
    expect(uri.queryParameters.containsKey('origin'), isFalse);
  });

  test('share includes a maps link, fuel and qualified current price', () {
    final text = StationActions.shareText(station, FuelType.gasoline95);
    expect(text, contains('1,234 €/L'));
    expect(text, contains('Gasolina 95'));
    expect(text, contains('puede cambiar'));
    expect(text, contains('https://www.google.com/maps/search/'));
    expect(
      StationActions.shareText(station, FuelType.diesel),
      isNot(contains('1,234')),
    );
  });
}
