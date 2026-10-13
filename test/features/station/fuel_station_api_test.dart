import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:surtio/features/map/data/services/fuel_station_api.dart';

String responseBody() => jsonEncode({
  'ListaEESSPrecio': [
    {
      'IDEESS': '1',
      'Rótulo': 'Estación',
      'Latitud': '28,1',
      'Longitud (WGS84)': '-15,4',
      'Precio Gasolina 95 E5': '1,234',
    },
    {'IDEESS': '2', 'Latitud': '', 'Longitud (WGS84)': ''},
  ],
});

void main() {
  setUp(FuelStationApi.clearMemoryCacheForTesting);

  test('shares concurrent requests and caches the national list', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 1));
      return http.Response.bytes(utf8.encode(responseBody()), 200);
    });
    await http.runWithClient(() async {
      final results = await Future.wait([
        const FuelStationApi().fetchStations(),
        const FuelStationApi().fetchStations(),
      ]);
      expect(calls, 1);
      expect(results.first.length, 1);
      expect(results.first.first.gasoline95Price, 1.234);
      await const FuelStationApi().fetchStations();
      expect(calls, 1);
      await const FuelStationApi().fetchStations(forceRefresh: true);
      expect(calls, 2);
    }, () => client);
  });

  test('failed responses can be retried without poisoning the cache', () async {
    var calls = 0;
    await http.runWithClient(
      () async {
        await expectLater(
          const FuelStationApi().fetchStations(),
          throwsA(isA<http.ClientException>()),
        );
        final result = await const FuelStationApi().fetchStations();
        expect(result.single.id, '1');
        expect(calls, 2);
      },
      () => MockClient(
        (_) async => ++calls == 1
            ? http.Response('Unavailable', 503)
            : http.Response.bytes(utf8.encode(responseBody()), 200),
      ),
    );
  });

  test('an invalid payload produces a recoverable error', () async {
    await http.runWithClient(() async {
      await expectLater(
        const FuelStationApi().fetchStations(),
        throwsFormatException,
      );
    }, () => MockClient((_) async => http.Response('{}', 200)));
  });
}
