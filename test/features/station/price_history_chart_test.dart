import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surtio/features/station/data/models/fuel_price_history_point.dart';
import 'package:surtio/features/station/presentation/widgets/price_history_chart.dart';

void main() {
  testWidgets('touching the chart selects and describes the nearest point', (
    tester,
  ) async {
    final points = [
      FuelPriceHistoryPoint(date: DateTime(2026, 9, 20), price: 1.45),
      FuelPriceHistoryPoint(date: DateTime(2026, 9, 21), price: 1.47),
      FuelPriceHistoryPoint(date: DateTime(2026, 9, 22), price: 1.49),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 320, child: PriceHistoryChart(points: points)),
        ),
      ),
    );

    final chart = find.byType(PriceHistoryChart);
    await tester.tapAt(tester.getTopRight(chart) - const Offset(6, -50));
    await tester.pump();

    expect(find.textContaining('1,490 €/L'), findsOneWidget);
    expect(find.textContaining('22/9/2026'), findsOneWidget);
  });
}
