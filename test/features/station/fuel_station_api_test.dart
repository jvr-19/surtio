import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:surtio/features/map/data/services/fuel_station_api.dart';
import 'package:surtio/features/map/data/services/station_cache.dart';

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
  test(
    'successful prices survive restart and failed refresh keeps their original date',
    () async {
      final store = _MemoryCache();
      final time = DateTime.utc(2026, 10, 13, 12);
      final api = FuelStationApi(cache: store, clock: () => time);
      var fail = false;
      await http.runWithClient(
        () async {
          await api.fetchStations();
          expect(store.data!.queriedAt, time);
          FuelStationApi.clearMemoryCacheForTesting();
          fail = true;
          final saved = await api.fetchStations();
          expect(saved.single.gasoline95Price, 1.234);
          expect(FuelStationApi.usingSavedPrices, isTrue);
          expect(FuelStationApi.lastUpdated, time);
          fail = false;
          await api.fetchStations(forceRefresh: true);
          expect(FuelStationApi.usingSavedPrices, isFalse);
        },
        () => MockClient(
          (_) async => fail
              ? http.Response('offline', 503)
              : http.Response.bytes(utf8.encode(responseBody()), 200),
        ),
      );
    },
  );

  test(
    'prices older than 24 hours or dated in the future are rejected',
    () async {
      final time = DateTime.utc(2026, 10, 13, 12);
      for (final timestamp in [
        time.subtract(const Duration(hours: 25)),
        time.add(const Duration(minutes: 1)),
      ]) {
        FuelStationApi.clearMemoryCacheForTesting();
        final store = _MemoryCache()
          ..data = SavedStationData(
            jsonDecode(responseBody()) as Map<String, dynamic>,
            timestamp,
          );
        await http.runWithClient(() async {
          await expectLater(
            FuelStationApi(cache: store, clock: () => time).fetchStations(),
            throwsA(isA<http.ClientException>()),
          );
        }, () => MockClient((_) async => http.Response('offline', 503)));
      }
    },
  );

  test('invalid saved data never becomes a price list', () async {
    final store = _MemoryCache()
      ..data = SavedStationData({'ListaEESSPrecio': []}, DateTime.now());
    await http.runWithClient(() async {
      await expectLater(
        FuelStationApi(cache: store).fetchStations(),
        throwsA(isA<http.ClientException>()),
      );
    }, () => MockClient((_) async => http.Response('offline', 503)));
  });

  test('a disk write failure does not lose valid in-memory prices', () async {
    final store = _MemoryCache()..failWrites = true;
    var offline = false;
    await http.runWithClient(
      () async {
        final api = FuelStationApi(cache: store);
        await api.fetchStations();
        offline = true;
        final result = await api.fetchStations(forceRefresh: true);
        expect(result.single.id, '1');
        expect(FuelStationApi.usingSavedPrices, isTrue);
      },
      () => MockClient(
        (_) async => offline
            ? http.Response('offline', 503)
            : http.Response.bytes(utf8.encode(responseBody()), 200),
      ),
    );
  });
  test(
    'invalid or zero prices are unavailable, never the cheapest result',
    () async {
      final payload = jsonEncode({
        'ListaEESSPrecio': [
          {
            'IDEESS': '1',
            'Latitud': '28,1',
            'Longitud (WGS84)': '-15,4',
            'Precio Gasolina 95 E5': 'NaN',
            'Precio Gasolina 98 E5': '0,000',
            'Precio Gasoleo Premium': 'Infinity',
            'Precio Gases licuados del petróleo': '-1',
            'Precio Gasoleo A': '1,700',
          },
        ],
      });
      await http.runWithClient(
        () async {
          final station = (await const FuelStationApi().fetchStations()).single;
          expect(station.gasoline95Price, isNull);
          expect(station.gasoline98Price, isNull);
          expect(station.premiumDieselPrice, isNull);
          expect(station.lpgPrice, isNull);
          expect(station.dieselPrice, 1.7);
        },
        () => MockClient(
          (_) async => http.Response.bytes(utf8.encode(payload), 200),
        ),
      );
    },
  );
}

class _MemoryCache implements StationCache {
  SavedStationData? data;
  bool failWrites = false;
  @override
  Future<SavedStationData?> read() async => data;
  @override
  Future<void> write(SavedStationData value) async {
    if (failWrites) throw StateError('disk unavailable');
    data = value;
  }
}
