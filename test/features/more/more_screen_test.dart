import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surtio/features/more/presentation/more_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'privacy explains manual location, local data and external providers',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MoreScreen()));
      await tester.tap(find.text('Privacidad'));
      await tester.pumpAndSettle();
      expect(find.textContaining('support@jvrlabs.es'), findsWidgets);
      expect(find.textContaining('OpenFreeMap'), findsWidgets);
      expect(find.textContaining('segundo plano'), findsOneWidget);
    },
  );

  testWidgets('favorites opens with a useful empty state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MoreScreen()));
    await tester.tap(find.text('Mis favoritos'));
    await tester.pumpAndSettle();
    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.textContaining('Guarda una estación'), findsOneWidget);
  });
}
