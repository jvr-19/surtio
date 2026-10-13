import 'package:flutter/material.dart';

import '../../features/map/data/models/fuel_station.dart';
import '../../features/map/data/services/fuel_station_api.dart';
import 'search_area.dart';

Future<void> pickSearchArea(BuildContext context) async {
  final area = await showModalBottomSheet<SearchArea>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _AreaPicker(),
  );
  if (area != null) SearchAreaController.instance.select(area);
}

class _AreaPicker extends StatefulWidget {
  const _AreaPicker();
  @override
  State<_AreaPicker> createState() => _AreaPickerState();
}

class _AreaPickerState extends State<_AreaPicker> {
  late Future<List<FuelStation>> _stations;
  String _query = '';
  @override
  void initState() {
    super.initState();
    _stations = const FuelStationApi().fetchStations();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .7,
      child: Column(
        children: [
          const Text(
            'Elegir zona',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Municipio o provincia',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<FuelStation>>(
              future: _stations,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: FilledButton(
                      onPressed: () => setState(
                        () =>
                            _stations = const FuelStationApi().fetchStations(),
                      ),
                      child: const Text('Reintentar carga de municipios'),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final municipalities = <String, FuelStation>{};
                for (final station in snapshot.data!) {
                  if (station.municipalityId.isNotEmpty &&
                      station.municipality.isNotEmpty) {
                    municipalities.putIfAbsent(
                      station.municipalityId,
                      () => station,
                    );
                  }
                }
                final matches =
                    municipalities.values
                        .where(
                          (station) => _normalize(
                            '${station.municipality} ${station.province}',
                          ).contains(_normalize(_query)),
                        )
                        .toList()
                      ..sort(
                        (a, b) => a.municipality.compareTo(b.municipality),
                      );
                if (matches.isEmpty) {
                  return const Center(
                    child: Text('No hay municipios con ese nombre.'),
                  );
                }
                return ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final station = matches[index];
                    return ListTile(
                      title: Text(station.municipality),
                      subtitle: Text(station.province),
                      onTap: () => Navigator.pop(
                        context,
                        SearchArea(
                          latitude: station.latitude,
                          longitude: station.longitude,
                          label: station.municipality,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  static String _normalize(String value) {
    var result = value.toLowerCase().trim();
    for (final entry in {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
    }.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }
}
