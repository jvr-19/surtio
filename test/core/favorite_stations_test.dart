import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surtio/core/stations/favorite_stations.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('favorites survive a new repository and can be removed', () async {
    final favorites = FavoriteStations();
    await favorites.toggle('station-1');
    final restored = FavoriteStations();
    await restored.load();
    expect(restored.contains('station-1'), isTrue);
    await restored.toggle('station-1');
    final removed = FavoriteStations();
    await removed.load();
    expect(removed.ids, isEmpty);
  });

  test('simultaneous changes do not overwrite each other', () async {
    final favorites = FavoriteStations();
    await Future.wait([favorites.toggle('a'), favorites.toggle('b')]);
    expect(favorites.ids, {'a', 'b'});
    await Future.wait([favorites.toggle('a'), favorites.toggle('a')]);
    expect(favorites.ids, {'a', 'b'});
  });
}
