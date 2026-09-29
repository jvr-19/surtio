import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surtio/features/nearby/presentation/nearby_screen.dart';
import 'package:surtio/features/vehicle/data/models/vehicle_profile.dart';
import 'package:surtio/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:surtio/features/vehicle/presentation/vehicle_screen.dart';

void main() {
  testWidgets('Nearby screen renders correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NearbyScreen())),
    );

    expect(find.text('Cerca'), findsOneWidget);
  });

  testWidgets('Vehicle screen renders correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: VehicleScreen(repository: _EmptyRepository())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mi coche'), findsOneWidget);
  });
}

class _EmptyRepository implements VehicleProfileRepository {
  @override
  Future<VehicleProfile?> load() async => null;

  @override
  Future<void> save(VehicleProfile profile) async {}
}
