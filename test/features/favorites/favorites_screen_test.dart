import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surtio/core/stations/favorite_stations.dart';
import 'package:surtio/core/stations/fuel_selection.dart';
import 'package:surtio/features/favorites/presentation/favorites_screen.dart';
import 'package:surtio/features/map/data/models/fuel_station.dart';
import 'package:surtio/features/map/data/services/fuel_station_api.dart';

void main() {
  testWidgets(
    'favorites compare the selected fuel and keep unavailable stations',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        FavoriteStations.storageKey: ['1', '2'],
      });
      final favorites = FavoriteStations();
      final fuel = FuelSelection()..select(FuelType.gasoline95);
      await tester.pumpWidget(
        MaterialApp(
          home: FavoritesScreen(
            api: const _Stations(),
            favorites: favorites,
            fuelSelection: fuel,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('1,500 €/L'), findsNWidgets(2));
      await tester.tap(find.byType(DropdownButton<FuelType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(FuelType.diesel.fullName).last);
      await tester.pumpAndSettle();
      expect(find.textContaining('1,400 €/L'), findsOneWidget);
      expect(
        find.textContaining('Sin precio disponible para este carburante'),
        findsOneWidget,
      );
      expect(find.text('Estación 2'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      favorites.dispose();
      fuel.dispose();
    },
  );

  testWidgets('favorite prices fit a narrow screen with double text size', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      FavoriteStations.storageKey: ['1', '2'],
    });
    final favorites = FavoriteStations();
    final fuel = FuelSelection()..select(FuelType.premiumDiesel);
    tester.view.physicalSize = const Size(360, 800);
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
        home: FavoritesScreen(
          api: const _Stations(),
          favorites: favorites,
          fuelSelection: fuel,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    favorites.dispose();
    fuel.dispose();
  });
}

class _Stations extends FuelStationApi {
  const _Stations();
  @override
  Future<List<FuelStation>> fetchStations({bool forceRefresh = false}) async =>
      [
        for (final id in ['1', '2'])
          FuelStation(
            id: id,
            name: 'Estación $id',
            address: 'Dirección de prueba',
            municipality: 'Municipio de prueba',
            municipalityId: '1',
            province: 'Provincia',
            latitude: 28.1,
            longitude: -15.4,
            schedule: '24H',
            gasoline95Price: 1.5,
            dieselPrice: id == '1' ? 1.4 : null,
          ),
      ];
}
