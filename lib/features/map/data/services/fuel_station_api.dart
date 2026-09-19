import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/fuel_station.dart';

class FuelStationApi {
  const FuelStationApi();

  static final Uri _endpoint = Uri.parse(
    'https://sedeaplicaciones.minetur.gob.es/'
    'ServiciosRESTCarburantes/PreciosCarburantes/'
    'EstacionesTerrestres/',
  );

  Future<List<FuelStation>> fetchStations() async {
    final response = await http.get(_endpoint);

    if (response.statusCode != 200) {
      throw Exception('Error loading fuel stations: ${response.statusCode}');
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes));

    final stationsJson = json['ListaEESSPrecio'] as List<dynamic>? ?? const [];

    return stationsJson
        .map((station) => FuelStation.fromJson(station as Map<String, dynamic>))
        .toList();
  }
}
