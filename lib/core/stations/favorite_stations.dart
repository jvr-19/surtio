import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteStations extends ChangeNotifier {
  FavoriteStations();
  static final instance = FavoriteStations();
  static const storageKey = 'favorite_station_ids_v1';
  Set<String> _ids = {};
  Future<void>? _loading;
  Future<void> _writes = Future.value();

  Set<String> get ids => Set.unmodifiable(_ids);
  bool contains(String id) => _ids.contains(id);

  Future<void> load() => _loading ??= _read();

  Future<void> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _ids = (prefs.getStringList(storageKey) ?? []).toSet();
      notifyListeners();
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  Future<void> toggle(String id) {
    final operation = _writes.then((_) async {
      await load();
      final next = {..._ids};
      if (!next.add(id)) next.remove(id);
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setStringList(storageKey, next.toList()..sort())) {
        throw StateError('No se pudieron guardar los favoritos');
      }
      _ids = next;
      notifyListeners();
    });
    _writes = operation.catchError((Object _) {});
    return operation;
  }
}
