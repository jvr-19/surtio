import 'package:flutter/material.dart';

import '../../../core/stations/favorite_stations.dart';
import '../../../shared/widgets/price_freshness.dart';
import '../../map/data/models/fuel_station.dart';
import '../../map/data/services/fuel_station_api.dart';
import '../../station/presentation/station_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favorites = FavoriteStations.instance;
  late Future<List<FuelStation>> _stations;
  DateTime? _queriedAt;
  bool _usingSavedPrices = false;
  @override
  void initState() {
    super.initState();
    _stations = _load();
  }

  Future<List<FuelStation>> _load({bool refresh = false}) async {
    await _favorites.load();
    if (_favorites.ids.isEmpty) return [];
    final stations = await const FuelStationApi().fetchStations(
      forceRefresh: refresh,
    );
    _queriedAt = FuelStationApi.lastUpdated;
    _usingSavedPrices = FuelStationApi.usingSavedPrices;
    return stations;
  }

  Future<void> _refresh() async {
    final request = _load(refresh: true);
    setState(() => _stations = request);
    try {
      await request;
    } catch (_) {
      /* FutureBuilder renders the retry. */
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Favoritos'),
      actions: [
        IconButton(
          tooltip: 'Actualizar precios',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ListenableBuilder(
      listenable: _favorites,
      builder: (context, _) => FutureBuilder<List<FuelStation>>(
        future: _stations,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: FilledButton(
                onPressed: _refresh,
                child: const Text('Reintentar carga de favoritos'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_favorites.ids.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Guarda una estación desde su detalle para encontrarla aquí.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final stations = snapshot.data!
              .where((s) => _favorites.contains(s.id))
              .toList();
          final missing = _favorites.ids.difference(
            stations.map((s) => s.id).toSet(),
          );
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                PriceFreshness(
                  queriedAt: _queriedAt,
                  usingSavedPrices: _usingSavedPrices,
                ),
                const Text('Desliza para actualizar los precios.'),
                const SizedBox(height: 12),
                for (final station in stations)
                  Card(
                    child: ListTile(
                      title: Text(station.name),
                      subtitle: Text(
                        '${station.address}\n${station.municipality}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StationDetailScreen(
                            station: station,
                            queriedAt: _queriedAt,
                            usingSavedPrices: _usingSavedPrices,
                            distanceKm: null,
                          ),
                        ),
                      ),
                    ),
                  ),
                for (final id in missing)
                  ListTile(
                    title: const Text(
                      'Estación ya no disponible en la fuente oficial',
                    ),
                    subtitle: Text('Identificador: $id'),
                    trailing: IconButton(
                      tooltip: 'Quitar favorito',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        try {
                          await _favorites.toggle(id);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No se pudo quitar el favorito.'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
