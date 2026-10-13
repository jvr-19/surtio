import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:surtio/app/app.dart';
import 'package:surtio/core/location/search_area.dart';
import 'package:surtio/core/stations/favorite_stations.dart';
import 'package:surtio/features/map/data/services/fuel_station_api.dart';
import 'package:surtio/features/map/domain/services/station_distance_service.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'manual area, real prices, station detail, favorites and privacy',
    (tester) async {
      SearchAreaController.instance.selectRadius(20);
      SearchAreaController.instance.select(
        const SearchArea(
          latitude: 28.1,
          longitude: -15.4167,
          label: 'Las Palmas de Gran Canaria',
        ),
      );
      final stations = await const FuelStationApi().fetchStations();
      final nearby = const StationDistanceService()
          .nearbyStations(
            stations: stations,
            latitude: 28.1,
            longitude: -15.4167,
          )
          .where((s) => s.gasoline95Price != null)
          .toList();
      expect(
        nearby,
        isNotEmpty,
        reason: 'The live official data must contain nearby fuel prices.',
      );
      final station = nearby.first;
      final favorites = FavoriteStations.instance;
      await favorites.load();
      final initiallySaved = favorites.contains(station.id);

      await tester.pumpWidget(const SurtioApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Cerca').last);
      await waitFor(tester, find.text(station.name).first);
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('01-nearby');
      expect(find.textContaining('Consulta:'), findsWidgets);
      await tester.enterText(find.byType(TextField), station.name);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(station.name), findsWidgets);
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.widgetWithText(ChoiceChip, '50 km'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Mapa').last);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('50 km'), findsOneWidget);
      await binding.takeScreenshot('07-map');
      await tester.tap(find.text('Cerca').last);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.widgetWithText(ChoiceChip, '20 km'));
      await waitFor(tester, find.text(station.name).first);

      await tester.tap(find.text(station.name).first);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Ir ahora'), findsOneWidget);
      if (!initiallySaved) {
        await tester.tap(find.text('Guardar'));
        await waitFor(tester, find.text('Guardada'));
      }
      expect(favorites.contains(station.id), isTrue);
      await binding.takeScreenshot('02-station-detail');
      await tester.tap(find.byTooltip('Volver'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Más').last);
      await tester.pump(const Duration(milliseconds: 500));
      await binding.takeScreenshot('03-more');
      await tester.tap(find.text('Mis favoritos'));
      await waitFor(tester, find.text(station.name));
      await binding.takeScreenshot('04-favorites');
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Privacidad'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('support@jvrlabs.es'), findsWidgets);
      await binding.takeScreenshot('05-privacy');
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Cerca').last);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Cambiar'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(find.byType(TextField).last, 'Arucas');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.widgetWithText(ListTile, 'Arucas'));
      await waitFor(tester, find.text('Zona: Arucas'));
      await binding.takeScreenshot('06-manual-area');
      expect(SearchAreaController.instance.area.isDevice, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      if (!initiallySaved) await favorites.toggle(station.id);
    },
  );
}

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}
