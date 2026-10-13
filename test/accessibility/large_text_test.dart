import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surtio/features/map/data/models/fuel_station.dart';
import 'package:surtio/features/station/presentation/station_detail_screen.dart';
import 'package:surtio/features/more/presentation/more_screen.dart';
import 'package:surtio/features/vehicle/presentation/vehicle_form_screen.dart';

void main() {
  testWidgets('Vehicle form can be scrolled with large text and keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const VehicleFormScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Mi coche');
    await tester.scrollUntilVisible(
      find.text('Guardar coche'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Station detail and information remain usable with large text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget app(Widget screen) => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: screen,
    );
    const station = FuelStation(
      id: 'test',
      name: 'ESTACIÓN DE PRUEBA',
      address: 'Dirección de prueba',
      municipality: 'Prueba',
      municipalityId: '1',
      province: 'Prueba',
      latitude: 28.1,
      longitude: -15.4,
      schedule: '24H',
      gasoline95Price: 1.5,
      dieselPrice: 1.4,
    );
    await tester.pumpWidget(
      app(const StationDetailScreen(station: station, distanceKm: 1)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 5; i++) {
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -350),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(const MoreScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(
      find.text('Privacidad'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Privacidad'));
    await tester.pumpAndSettle();
    expect(find.textContaining('segundo plano'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
