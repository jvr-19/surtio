import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surtio/features/nearby/presentation/nearby_screen.dart';
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
      const MaterialApp(home: Scaffold(body: VehicleScreen())),
    );

    expect(find.text('Mi coche'), findsOneWidget);
  });
}
