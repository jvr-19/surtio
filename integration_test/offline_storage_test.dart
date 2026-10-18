import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:surtio/features/map/data/services/fuel_station_api.dart';
import 'package:surtio/features/map/data/services/station_cache.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android disk cache survives memory reset and rejects expired offline prices',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'surtio-offline-check-',
      );
      final store = FileStationCache(directoryPath: directory.path);
      final queriedAt = DateTime(2026, 10, 18, 12);
      var offline = false;
      var now = queriedAt;
      try {
        FuelStationApi.clearMemoryCacheForTesting();
        await http.runWithClient(
          () async {
            final api = FuelStationApi(cache: store, clock: () => now);
            final online = await api.fetchStations();
            expect(online.single.gasoline95Price, 1.234);
            expect((await store.read())!.queriedAt.toUtc(), queriedAt.toUtc());
            offline = true;
            FuelStationApi.clearMemoryCacheForTesting();
            now = queriedAt.add(const Duration(hours: 2));
            final saved = await api.fetchStations();
            expect(saved.single.id, 'offline-fixture');
            expect(FuelStationApi.usingSavedPrices, isTrue);
            expect(FuelStationApi.lastUpdated!.toUtc(), queriedAt.toUtc());
            FuelStationApi.clearMemoryCacheForTesting();
            now = queriedAt.add(const Duration(hours: 25));
            await expectLater(
              api.fetchStations(),
              throwsA(isA<http.ClientException>()),
            );
          },
          () => MockClient((request) async {
            if (offline) {
              throw http.ClientException(
                'Simulated connection loss',
                request.url,
              );
            }
            return http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'ListaEESSPrecio': [
                    {
                      'IDEESS': 'offline-fixture',
                      'Rótulo': 'Estación de prueba',
                      'Latitud': '28,1',
                      'Longitud (WGS84)': '-15,4',
                      'Precio Gasolina 95 E5': '1,234',
                    },
                  ],
                }),
              ),
              200,
            );
          }),
        );
      } finally {
        FuelStationApi.clearMemoryCacheForTesting();
        await directory.delete(recursive: true);
      }
    },
  );
}
