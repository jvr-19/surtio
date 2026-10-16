import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:surtio/core/legal/privacy_policy.dart';
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
  test('published privacy draft matches the in-app text', () {
    final html = File('docs/privacy-policy.html').readAsStringSync();
    for (final paragraph in PrivacyPolicy.text.split('\n\n')) {
      final content = paragraph
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;');
      for (final line in content.split('\n')) {
        expect(html, contains(line));
      }
    }
  });

  for (final available in [true, false]) {
    testWidgets('settings access handles availability: $available', (
      tester,
    ) async {
      const channel = MethodChannel('flutter.baseflow.com/geolocator');
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call.method);
        if (!available) throw PlatformException(code: 'unavailable');
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(const MaterialApp(home: MoreScreen()));
      await tester.scrollUntilVisible(
        find.text('Gestionar datos y permisos'),
        300,
      );
      await tester.tap(find.text('Gestionar datos y permisos'));
      await tester.pumpAndSettle();
      expect(calls, ['openAppSettings']);
      if (!available) {
        expect(find.textContaining('Abre Ajustes >'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
