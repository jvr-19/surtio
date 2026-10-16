import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/price_freshness.dart';
import '../../../core/location/search_area.dart';
import '../../../core/location/area_picker.dart';
import '../../../core/stations/fuel_selection.dart';
import '../../map/data/models/fuel_station.dart';
import '../../map/data/services/fuel_station_api.dart';
import '../../map/domain/services/station_distance_service.dart';
import '../../station/presentation/station_detail_screen.dart';

enum _NearbySort { distance, price }

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key, this.api = const FuelStationApi(), this.area});

  final FuelStationApi api;
  final SearchAreaController? area;

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  late final FuelStationApi _fuelStationApi = widget.api;
  late final _area = widget.area ?? SearchAreaController.instance;
  int _requestId = 0;
  final _fuelSelection = FuelSelection.instance;
  final StationDistanceService _distanceService = StationDistanceService();

  List<_NearbyStation> _allStations = [];
  List<_NearbyStation> _stations = [];

  double get _radiusKm => _area.radiusKm;
  String _query = '';

  bool _loading = true;
  String? _error;
  DateTime? _queriedAt;
  bool _usingSavedPrices = false;

  _NearbySort _sort = _NearbySort.distance;
  FuelType _selectedFuel = FuelType.gasoline95;

  @override
  void initState() {
    super.initState();
    _area.addListener(_areaChanged);
    _fuelSelection.addListener(_fuelChanged);
    _selectedFuel = _fuelSelection.value;
    _fuelSelection.initialize();
    _initialize();
  }

  Future<void> _initialize() async {
    await _area.initialize();
    if (mounted) await _loadStations();
  }

  void _fuelChanged() {
    if (mounted) _changeFuel(_fuelSelection.value);
  }

  void _areaChanged() {
    if (mounted) _loadStations();
  }

  @override
  void dispose() {
    _area.removeListener(_areaChanged);
    _fuelSelection.removeListener(_fuelChanged);
    super.dispose();
  }

  Future<void> _loadStations({bool refresh = false}) async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final position = _area.area;
      final stations = await _fuelStationApi.fetchStations(
        forceRefresh: refresh,
      );

      final nearby = _distanceService.nearbyStations(
        stations: stations,
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: _radiusKm,
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

      if (!mounted || requestId != _requestId) return;

      setState(() {
        _queriedAt = FuelStationApi.lastUpdated;
        _usingSavedPrices = FuelStationApi.usingSavedPrices;
        _allStations = result;
        _applyFuelFilter();
        _loading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar las estaciones cercanas.';
      });
    }
  }

  void _changeFuel(FuelType fuel) {
    if (fuel == _selectedFuel) return;
    setState(() {
      _selectedFuel = fuel;
      _applyFuelFilter();
    });
    _fuelSelection.select(fuel);
  }

  void _applyFuelFilter() {
    _stations = _allStations.where((item) {
      final station = item.station;
      return station.priceFor(_selectedFuel) != null &&
          '${station.name} ${station.address}'.toLowerCase().contains(_query);
    }).toList();

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
          if (View.of(context).viewInsets.bottom == 0)
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _area.area.isDevice
                        ? 'Gasolineras cerca de ti'
                        : 'Zona: ${_area.area.label}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => pickSearchArea(context),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Cambiar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (View.of(context).viewInsets.bottom == 0)
            _FuelSelector(selectedFuel: _selectedFuel, onSelected: _changeFuel),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              onChanged: (value) => setState(() {
                _query = value.trim().toLowerCase();
                _applyFuelFilter();
              }),
              decoration: const InputDecoration(
                hintText: 'Buscar estación o dirección',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (View.of(context).viewInsets.bottom == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Radio de búsqueda'),
                  for (final radius in SearchAreaController.radiusOptions)
                    ChoiceChip(
                      label: Text('${radius.toInt()} km'),
                      selected: _radiusKm == radius,
                      onSelected: _loading
                          ? null
                          : (selected) {
                              if (!selected) return;
                              _area.selectRadius(radius);
                            },
                    ),
                ],
              ),
            ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading && _allStations.isEmpty) {
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _query.isEmpty
                  ? 'No hay estaciones con este combustible a ${_radiusKm.toInt()} km.'
                  : 'No hay estaciones que coincidan con tu búsqueda.',
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () => pickSearchArea(context),
              child: const Text('Elegir otra zona'),
            ),
            TextButton(
              onPressed: () => _loadStations(refresh: true),
              child: const Text('Actualizar precios'),
            ),
          ],
        ),
      );
    }

    final lowestPrice = _stations
        .map((item) => item.station.priceFor(_selectedFuel)!)
        .reduce((a, b) => a < b ? a : b);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadStations(refresh: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (_loading)
            const SliverToBoxAdapter(child: LinearProgressIndicator()),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'Distancias en línea recta ${_area.area.isDevice ? "desde tu ubicación" : "desde un punto de la zona"}. Desliza para actualizar precios.',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: PriceFreshness(
                queriedAt: _queriedAt,
                usingSavedPrices: _usingSavedPrices,
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
                    label: _area.area.isDevice ? 'Distancia' : 'Desde zona',
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
                  queriedAt: _queriedAt,
                  usingSavedPrices: _usingSavedPrices,
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
    this.queriedAt,
    this.usingSavedPrices = false,
    required this.fuelType,
    required this.isLowestPrice,
  });

  final _NearbyStation item;
  final DateTime? queriedAt;
  final bool usingSavedPrices;
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
                queriedAt: queriedAt,
                usingSavedPrices: usingSavedPrices,
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
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: FuelType.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final fuel = FuelType.values[index];

          return _FuelChip(
            label: fuel.label,
            semanticLabel: fuel.fullName,
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
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label, semanticsLabel: semanticLabel),
    selected: selected,
    showCheckmark: false,
    selectedColor: AppColors.primary,
    backgroundColor: AppColors.surface,
    labelStyle: TextStyle(
      color: selected ? AppColors.background : AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    ),
    onSelected: (_) => onTap(),
  );
}

class _NearbyStation {
  const _NearbyStation({required this.station, required this.distanceKm});

  final FuelStation station;
  final double distanceKm;
}
