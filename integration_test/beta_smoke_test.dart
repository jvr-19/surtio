import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:surtio/app/app.dart';
import 'package:surtio/app/theme/app_theme.dart';
import 'package:surtio/features/map/presentation/map_screen.dart';
import 'package:surtio/core/location/search_area.dart';
import 'package:surtio/core/stations/favorite_stations.dart';
import 'package:surtio/features/map/data/services/fuel_station_api.dart';
import 'package:surtio/features/map/domain/services/station_distance_service.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (!const bool.fromEnvironment('MAP_TAP_ONLY')) {
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
        expect(find.textContaining('Consulta'), findsWidgets);
        await tester.enterText(find.byType(TextField), station.name);
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text(station.name), findsWidgets);
        await tester.enterText(find.byType(TextField), '');
        await tester.tap(find.widgetWithText(ChoiceChip, '50 km'));
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.text('Mapa').last);
        await tester.pump(const Duration(seconds: 2));
        expect(find.text('50 km'), findsOneWidget);
        for (var i = 0; i < 60; i++) {
          if (find.byType(LinearProgressIndicator).evaluate().isEmpty) break;
          await tester.pump(const Duration(milliseconds: 500));
        }
        expect(find.byType(LinearProgressIndicator), findsNothing);
        await tester.pump(const Duration(seconds: 1));
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
    testWidgets('Map remains usable with text at 200 percent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(body: SafeArea(child: MapScreen())),
        ),
      );
      await waitFor(tester, find.text('Más barata en la zona'));
      for (var i = 0; i < 60; i++) {
        if (find.byType(LinearProgressIndicator).evaluate().isEmpty) break;
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.ensureVisible(find.text('Ver detalles'));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('08-map-large-text');
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'A real marker tap selects its station and keeps the correct fuel',
    (tester) async {
      SearchAreaController.instance.select(
        const SearchArea(
          latitude: 28.1,
          longitude: -15.4167,
          label: 'Las Palmas de Gran Canaria',
        ),
      );
      SearchAreaController.instance.selectRadius(20);
      final data = await const FuelStationApi().fetchStations();
      final stations = const StationDistanceService()
          .nearbyStations(stations: data, latitude: 28.1, longitude: -15.4167)
          .where((s) => s.gasoline95Price != null)
          .toList();
      stations.sort((a, b) => b.gasoline95Price!.compareTo(a.gasoline95Price!));
      final target = stations.first;
      MapLibreMapController? controller;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: MapScreen(onMapCreated: (map) => controller = map),
          ),
        ),
      );
      await waitFor(tester, find.text('Más barata en la zona'));
      for (var i = 0; i < 60; i++) {
        if (find.byType(LinearProgressIndicator).evaluate().isEmpty) break;
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(controller, isNotNull);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      final map = controller!;
      await map.moveCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(target.latitude, target.longitude),
          17,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final rect = tester.getRect(find.byType(MapLibreMap));
      final ratio = tester.view.devicePixelRatio;
      final centerBelow = await map.toLatLng(
        math.Point(rect.width * ratio / 2, rect.height * ratio * 0.8),
      );
      await map.moveCamera(CameraUpdate.newLatLng(centerBelow));
      await tester.pump(const Duration(seconds: 1));
      final location = await map.toScreenLocation(
        LatLng(target.latitude, target.longitude),
      );
      final markerPoint = math.Point<double>(
        location.x.toDouble(),
        location.y.toDouble() - 18 * ratio,
      );
      final features = await map.queryRenderedFeatures(markerPoint, [
        'fuel-stations-markers',
      ], null);
      expect(
        features,
        isNotEmpty,
        reason: 'The tested tap must hit an actual rendered marker.',
      );
      final properties = (features.first as Map)['properties'] as Map;
      final selected = stations.firstWhere(
        (s) => s.id == properties['id'].toString(),
      );
      final tap =
          rect.topLeft + Offset(markerPoint.x / ratio, markerPoint.y / ratio);
      await tester.tapAt(tap);
      await waitFor(tester, find.text(selected.name));
      expect(find.text(selected.name), findsOneWidget);
      expect(find.text('Estación seleccionada'), findsOneWidget);
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('09-map-selected-station');
      await tester.tap(find.text('Diésel').first);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('95').first);
      await tester.pump(const Duration(seconds: 2));
      final latest = await map.queryRenderedFeatures(markerPoint, [
        'fuel-stations-markers',
      ], null);
      expect(latest, isNotEmpty);
      for (final feature in latest) {
        final p = (feature as Map)['properties'] as Map;
        final station = stations.firstWhere((s) => s.id == p['id'].toString());
        expect(p['price'], station.gasoline95Price);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
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
