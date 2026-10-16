import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  test('shared saved prices include the original query date', () {
    final text = StationActions.shareText(
      station,
      FuelType.gasoline95,
      queriedAt: DateTime(2026, 10, 12, 10),
    );
    expect(text, contains('Consulta: 12/10/2026 10:00'));
  });

  testWidgets(
    'failed navigation leaves the app usable and explains the failure',
    (tester) async {
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      MethodCall? sent;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        sent = call;
        return false;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => StationActions.navigate(context, station),
                child: const Text('Abrir ruta'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir ruta'));
      await tester.pumpAndSettle();
      expect(sent, isNotNull);
      expect(
        (sent!.arguments as Map)['url'],
        StationActions.routeUri(station).toString(),
      );
      expect(
        find.textContaining('No se pudo abrir el enlace.'),
        findsOneWidget,
      );
      expect(find.text('Abrir ruta'), findsOneWidget);
    },
  );

  testWidgets(
    'share cancellation is normal and a platform failure is recoverable',
    (tester) async {
      const channel = MethodChannel('dev.fluttercommunity.plus/share');
      bool failed = false;
      Map? params;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (failed) throw PlatformException(code: 'unavailable');
        params = call.arguments as Map;
        return 'dev.fluttercommunity.plus/share/dismissed';
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => StationActions.share(
                  context,
                  station,
                  FuelType.gasoline95,
                  queriedAt: DateTime(2026, 10, 12, 10),
                ),
                child: const Text('Compartir prueba'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Compartir prueba'));
      await tester.pumpAndSettle();
      expect(params!['text'], contains('Consulta: 12/10/2026 10:00'));
      expect(
        find.text('No se pudo abrir el menú para compartir.'),
        findsNothing,
      );
      failed = true;
      await tester.tap(find.text('Compartir prueba'));
      await tester.pumpAndSettle();
      expect(
        find.text('No se pudo abrir el menú para compartir.'),
        findsOneWidget,
      );
    },
  );
}
