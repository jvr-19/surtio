import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surtio/core/location/area_picker.dart';
import 'package:surtio/core/location/search_area.dart';
import 'package:surtio/features/map/data/models/fuel_station.dart';
import 'package:surtio/features/map/data/services/fuel_station_api.dart';

void main() {
  testWidgets(
    'municipality selection works with large text and an open keyboard',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 640);
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
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    pickSearchArea(context, api: const _Stations()),
                child: const Text('Elegir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Elegir'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), 'malaga');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(ListTile).first,
        80,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      expect(SearchAreaController.instance.area.label, 'Málaga');
      expect(find.text('Elegir zona'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
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
