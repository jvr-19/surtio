import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surtio/core/location/search_area.dart';
import 'package:surtio/features/map/data/models/fuel_station.dart';
import 'package:surtio/features/map/data/services/fuel_station_api.dart';
import 'package:surtio/features/nearby/presentation/nearby_screen.dart';

void main() {
  testWidgets('Nearby controls fit a narrow screen with larger text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SearchAreaController.instance.select(
      const SearchArea(
        latitude: 28.1,
        longitude: -15.4,
        label: 'Zona de prueba',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: const Scaffold(body: NearbyScreen(api: _Stations())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Search and radius change the available stations', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    SearchAreaController.instance.select(
      const SearchArea(
        latitude: 28.1,
        longitude: -15.4,
        label: 'Zona de prueba',
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NearbyScreen(api: _Stations())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ESTACION CERCANA'), findsOneWidget);
    expect(find.text('ESTACION LEJANA'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, '50 km'));
    await tester.pumpAndSettle();
    expect(find.text('2 estaciones'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  carretera  ');
    await tester.pumpAndSettle();
    expect(find.text('ESTACION CERCANA'), findsNothing);
    expect(find.text('ESTACION LEJANA'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pumpAndSettle();
    expect(
      find.text('No hay estaciones que coincidan con tu búsqueda.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('ESTACION CERCANA'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

class _Stations extends FuelStationApi {
  const _Stations();
  @override
  Future<List<FuelStation>> fetchStations({bool forceRefresh = false}) async =>
      [
        _station('1', 'ESTACION CERCANA', 'Calle Uno', 28.11),
        _station('2', 'ESTACION LEJANA', 'Carretera Dos', 28.4),
      ];
}

FuelStation _station(String id, String name, String address, double latitude) =>
    FuelStation(
      id: id,
      name: name,
      address: address,
      municipality: 'Prueba',
      municipalityId: '1',
      province: 'Prueba',
      latitude: latitude,
      longitude: -15.4,
      schedule: '24H',
      gasoline95Price: 1.5,
    );
