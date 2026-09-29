import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/location/location_service.dart';
import '../../map/data/models/fuel_station.dart';
import '../../map/data/services/fuel_station_api.dart';
import '../../map/domain/services/station_distance_service.dart';
import '../../station/presentation/station_detail_screen.dart';

enum _NearbySort { distance, price }

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final FuelStationApi _fuelStationApi = FuelStationApi();
  final LocationService _locationService = LocationService();
  final StationDistanceService _distanceService = StationDistanceService();

  List<_NearbyStation> _allStations = [];
  List<_NearbyStation> _stations = [];

  bool _loading = true;
  String? _error;

  _NearbySort _sort = _NearbySort.distance;
  FuelType _selectedFuel = FuelType.gasoline95;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      final stations = await _fuelStationApi.fetchStations();

      final nearby = _distanceService.nearbyStations(
        stations: stations,
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 20,
      );

      final result = nearby
          .map(
            (station) => _NearbyStation(
              station: station,
              distanceKm:
                  Geolocator.distanceBetween(
                    position.latitude,
                    position.longitude,
                    station.latitude,
                    station.longitude,
                  ) /
                  1000,
            ),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _allStations = result;
        _applyFuelFilter();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar las estaciones cercanas.';
      });
    }
  }

  void _changeFuel(FuelType fuel) {
    setState(() {
      _selectedFuel = fuel;
      _applyFuelFilter();
    });
  }

  void _applyFuelFilter() {
    _stations = _allStations
        .where((item) => item.station.priceFor(_selectedFuel) != null)
        .toList();

    _sortStations();
  }

  void _changeSort(_NearbySort sort) {
    setState(() {
      _sort = sort;
      _sortStations();
    });
  }

  void _sortStations() {
    switch (_sort) {
      case _NearbySort.distance:
        _stations.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      case _NearbySort.price:
        _stations.sort(
          (a, b) => a.station
              .priceFor(_selectedFuel)!
              .compareTo(b.station.priceFor(_selectedFuel)!),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Text(
              'Cerca',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 3, 20, 0),
            child: Text(
              'Gasolineras cerca de ti',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
          const SizedBox(height: 18),
          _FuelSelector(selectedFuel: _selectedFuel, onSelected: _changeFuel),
          const SizedBox(height: 18),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.textSecondary,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadStations,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_stations.isEmpty) {
      return const Center(
        child: Text(
          'No hay estaciones con precio disponible.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final lowestPrice = _stations
        .map((item) => item.station.priceFor(_selectedFuel)!)
        .reduce((a, b) => a < b ? a : b);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadStations,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SummaryCard(
                lowestPrice: lowestPrice,
                stationCount: _stations.length,
                fuelType: _selectedFuel,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_stations.length} estaciones',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _SortButton(
                    label: 'Distancia',
                    selected: _sort == _NearbySort.distance,
                    onTap: () => _changeSort(_NearbySort.distance),
                  ),
                  const SizedBox(width: 8),
                  _SortButton(
                    label: 'Precio',
                    selected: _sort == _NearbySort.price,
                    onTap: () => _changeSort(_NearbySort.price),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList.separated(
              itemCount: _stations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _stations[index];

                return _StationCard(
                  item: item,
                  fuelType: _selectedFuel,
                  isLowestPrice:
                      item.station.priceFor(_selectedFuel) == lowestPrice,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.lowestPrice,
    required this.stationCount,
    required this.fuelType,
  });

  final double lowestPrice;
  final int stationCount;
  final FuelType fuelType;

  @override
  Widget build(BuildContext context) {
    final formattedPrice = lowestPrice.toStringAsFixed(3).replaceAll('.', ',');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2732), AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_gas_station_rounded,
              color: AppColors.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Desde ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(
                        text: '$formattedPrice €/L',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$stationCount estaciones con precio de ${fuelType.fullName}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({
    required this.item,
    required this.fuelType,
    required this.isLowestPrice,
  });

  final _NearbyStation item;
  final FuelType fuelType;
  final bool isLowestPrice;

  @override
  Widget build(BuildContext context) {
    final station = item.station;

    final price = station
        .priceFor(fuelType)!
        .toStringAsFixed(3)
        .replaceAll('.', ',');

    final distance = item.distanceKm < 1
        ? '${(item.distanceKm * 1000).round()} m'
        : '${item.distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StationDetailScreen(
                station: item.station,
                distanceKm: item.distanceKm,
                initialFuel: fuelType,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isLowestPrice
                  ? AppColors.primary.withValues(alpha: 0.65)
                  : AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5FAF9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_gas_station_rounded,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLowestPrice) ...[
                      const Row(
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            color: Color(0xFFFFD600),
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Precio más bajo',
                            style: TextStyle(
                              color: Color(0xFFFFD600),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      station.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      station.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.near_me_outlined,
                          color: AppColors.textSecondary,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distance,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    '€/L',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      fuelType.label,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FuelSelector extends StatelessWidget {
  const _FuelSelector({required this.selectedFuel, required this.onSelected});

  final FuelType selectedFuel;
  final ValueChanged<FuelType> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: FuelType.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final fuel = FuelType.values[index];

          return _FuelChip(
            label: fuel.label,
            selected: fuel == selectedFuel,
            onTap: () => onSelected(fuel),
          );
        },
      ),
    );
  }
}

class _FuelChip extends StatelessWidget {
  const _FuelChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.background : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NearbyStation {
  const _NearbyStation({required this.station, required this.distanceKm});

  final FuelStation station;
  final double distanceKm;
}
