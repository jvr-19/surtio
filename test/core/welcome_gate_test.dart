import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surtio/app/welcome_gate.dart';
import 'package:surtio/core/location/location_service.dart';
import 'package:surtio/core/location/search_area.dart';
import 'package:surtio/features/map/data/models/fuel_station.dart';
import 'package:surtio/features/map/data/services/fuel_station_api.dart';

void main() {
  testWidgets('welcome does not request location and can be skipped once', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final location = _Location(const PermissionDeniedException('denied'));
    final area = SearchAreaController(locationService: location);
    Widget app() => MaterialApp(
      home: WelcomeGate(area: area, child: const Text('Dentro')),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(location.calls, 0);
    expect(find.text('Elegir municipio'), findsOneWidget);
    await tester.tap(find.text('Explorar sin elegir zona'));
    await tester.pumpAndSettle();
    expect(find.text('Dentro'), findsOneWidget);
    expect(location.calls, 0);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Dentro'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    area.dispose();
  });

  testWidgets(
    'explicit approximate location completes welcome without persisting coordinates',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final area = SearchAreaController(
        locationService: _ApproximateLocation(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeGate(area: area, child: const Text('Dentro')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usar mi ubicación'));
      await tester.pumpAndSettle();
      expect(find.text('Dentro'), findsOneWidget);
      expect(area.area.isDevice, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(WelcomeGate.storageKey), isTrue);
      expect(prefs.getString('manual_search_area'), isNull);
      await tester.pumpWidget(const SizedBox());
      area.dispose();
    },
  );

  for (final error in <Object>[
    const PermissionDeniedException('deniedForever'),
    const LocationServiceDisabledException(),
    TimeoutException('timeout'),
  ]) {
    testWidgets(
      'location failure leaves manual selection usable: ${error.runtimeType}',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final location = _Location(error);
        final area = SearchAreaController(locationService: location);
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: WelcomeGate(
              area: area,
              api: const _Stations(),
              child: const Text('Dentro'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(location.calls, 0);
        await tester.ensureVisible(find.text('Usar mi ubicación'));
        await tester.tap(find.text('Usar mi ubicación'));
        await tester.pumpAndSettle();
        expect(location.calls, 1);
        expect(
          find.textContaining(
            error is TimeoutException
                ? 'a tiempo'
                : error is PermissionDeniedException
                ? 'No se ha concedido'
                : 'desactivada',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Elegir municipio'));
        await tester.tap(find.text('Elegir municipio'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'malaga');
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byType(ListTile).first,
          80,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle();
        expect(find.text('Dentro'), findsOneWidget);
        expect(area.area.label, 'Málaga');
        expect(area.area.isDevice, isFalse);
        expect(location.calls, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        area.dispose();
      },
    );
  }

  testWidgets('dismissing municipality picker does not complete welcome', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final area = SearchAreaController();
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomeGate(
          area: area,
          api: const _Stations(),
          child: const Text('Dentro'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir municipio'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Elegir municipio'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(WelcomeGate.storageKey), isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    area.dispose();
  });
}

class _Location extends LocationService {
  _Location(this.error);
  final Object error;
  int calls = 0;
  @override
  Future<Position> getCurrentPosition() async {
    calls++;
    throw error;
  }
}

class _Stations extends FuelStationApi {
  const _Stations();
  @override
  Future<List<FuelStation>> fetchStations({bool forceRefresh = false}) async =>
      const [
        FuelStation(
          id: '1',
          name: 'Estación',
          address: 'Dirección',
          municipality: 'Málaga',
          municipalityId: '1',
          province: 'Málaga',
          latitude: 36.72,
          longitude: -4.42,
          schedule: '24H',
        ),
      ];
}

class _ApproximateLocation extends LocationService {
  @override
  Future<Position> getCurrentPosition() async => Position(
    latitude: 40.4,
    longitude: -3.7,
    timestamp: DateTime(2026, 10, 18),
    accuracy: 2000,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}
