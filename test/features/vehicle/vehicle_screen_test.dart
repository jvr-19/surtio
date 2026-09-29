import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surtio/app/theme/app_theme.dart';
import 'package:surtio/features/map/data/models/fuel_station.dart';
import 'package:surtio/features/vehicle/data/models/vehicle_profile.dart';
import 'package:surtio/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:surtio/features/vehicle/presentation/vehicle_screen.dart';

void main() {
  testWidgets('shows an honest empty state without a saved vehicle', (
    tester,
  ) async {
    await tester.pumpWidget(_appWithRepository(_FakeRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Mi coche'), findsOneWidget);
    expect(find.text('Añade tu coche'), findsOneWidget);
    expect(find.text('Añadir coche'), findsOneWidget);
  });

  testWidgets('shows saved vehicle data and deterministic statistics', (
    tester,
  ) async {
    const profile = VehicleProfile(
      name: 'Seat León',
      variant: '1.5 TSI',
      fuelType: FuelType.gasoline95,
      averageConsumption: 6.1,
      tankCapacity: 50,
    );
    await tester.pumpWidget(
      _appWithRepository(_FakeRepository(profile: profile)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Seat León'), findsOneWidget);
    expect(find.text('1.5 TSI · Gasolina 95'), findsOneWidget);
    expect(find.text('6,1'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('~820'), findsOneWidget);
    expect(find.text('Recomendación en preparación'), findsOneWidget);
  });
}

Widget _appWithRepository(VehicleProfileRepository repository) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: VehicleScreen(repository: repository)),
  );
}

class _FakeRepository implements VehicleProfileRepository {
  _FakeRepository({this.profile});

  VehicleProfile? profile;

  @override
  Future<VehicleProfile?> load() async => profile;

  @override
  Future<void> save(VehicleProfile profile) async {
    this.profile = profile;
  }
}
