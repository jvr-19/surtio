import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/fuel_station.dart';
import 'station_cache.dart';

class FuelStationApi {
  const FuelStationApi({this.cache = const FileStationCache(), this.clock});
  final StationCache cache;
  final DateTime Function()? clock;
  DateTime get _now => clock?.call() ?? DateTime.now();
  static bool usingSavedPrices = false;

  static final Uri endpoint = Uri.parse(
    'https://sedeaplicaciones.minetur.gob.es/'
    'ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/',
  );
  static List<FuelStation>? _cached;
  static DateTime? lastUpdated;
  static Future<List<FuelStation>>? _pending;

  Future<List<FuelStation>> fetchStations({bool forceRefresh = false}) {
    if (_pending != null) return _pending!;
    if (!forceRefresh &&
        !usingSavedPrices &&
        _cached != null &&
        lastUpdated != null &&
        !_now.difference(lastUpdated!).isNegative &&
        _now.difference(lastUpdated!) < const Duration(minutes: 10)) {
      return Future.value(_cached!);
    }
    final request = _fetch();
    _pending = request;
    return request.whenComplete(() => _pending = null);
  }

  static void clearMemoryCacheForTesting() {
    _cached = null;
    lastUpdated = null;
    _pending = null;
    usingSavedPrices = false;
  }

  Future<List<FuelStation>> _fetch() async {
    final client = http.Client();
    try {
      final response = await client
          .get(endpoint)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw http.ClientException(
          'Error loading stations: ${response.statusCode}',
          endpoint,
        );
      }
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final stations = _parseStations(json);
      _cached = List.unmodifiable(stations);
      lastUpdated = _now;
      usingSavedPrices = false;
      try {
        await cache.write(
          SavedStationData(json as Map<String, dynamic>, lastUpdated!),
        );
      } catch (_) {
        // Disk availability must not turn a successful query into an error.
      }
      return _cached!;
    } catch (_) {
      if (_cached != null && lastUpdated != null && _isUsable(lastUpdated!)) {
        usingSavedPrices = true;
        return _cached!;
      }
      SavedStationData? saved;
      try {
        saved = await cache.read();
      } catch (_) {
        /* Keep the network error. */
      }
      if (saved != null) {
        if (_isUsable(saved.queriedAt)) {
          try {
            _cached = List.unmodifiable(_parseStations(saved.payload));
            lastUpdated = saved.queriedAt;
            usingSavedPrices = true;
            return _cached!;
          } catch (_) {
            // An invalid saved response is never presented as a price list.
          }
        }
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  bool _isUsable(DateTime time) {
    final age = _now.difference(time);
    return !age.isNegative && age <= const Duration(hours: 24);
  }

  static List<FuelStation> _parseStations(dynamic json) {
    if (json is! Map<String, dynamic> || json['ListaEESSPrecio'] is! List) {
      throw const FormatException('Respuesta de estaciones no válida');
    }
    final stations = (json['ListaEESSPrecio'] as List)
        .whereType<Map<String, dynamic>>()
        .map(FuelStation.fromJson)
        .where(
          (s) =>
              s.id.isNotEmpty &&
              s.latitude.isFinite &&
              s.longitude.isFinite &&
              s.latitude >= -90 &&
              s.latitude <= 90 &&
              s.longitude >= -180 &&
              s.longitude <= 180 &&
              (s.latitude != 0 || s.longitude != 0),
        )
        .toList();
    if (stations.isEmpty) {
      throw const FormatException('No se recibieron estaciones');
    }
    return stations;
  }
}
