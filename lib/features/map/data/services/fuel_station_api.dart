import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/fuel_station.dart';

class FuelStationApi {
  const FuelStationApi();

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
        _cached != null &&
        lastUpdated != null &&
        DateTime.now().difference(lastUpdated!) < const Duration(minutes: 10)) {
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
      _cached = List.unmodifiable(stations);
      lastUpdated = DateTime.now();
      return _cached!;
    } finally {
      client.close();
    }
  }
}
