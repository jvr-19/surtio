import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/theme/app_colors.dart';
import 'widgets/map_header.dart';
import '../../../core/location/location_service.dart';
import '../../../core/map/map_config.dart';
import '../data/models/fuel_station.dart';
import '../data/services/fuel_station_api.dart';
import '../domain/services/station_distance_service.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(bottom: false, child: _MapContent());
  }
}

class _MapContent extends StatelessWidget {
  const _MapContent();

  @override
  Widget build(BuildContext context) {
    return const _MapPlaceholder();
  }
}

class _MapPlaceholder extends StatefulWidget {
  const _MapPlaceholder();

  @override
  State<_MapPlaceholder> createState() => _MapPlaceholderState();
}

class _MapPlaceholderState extends State<_MapPlaceholder> {
  final _locationService = const LocationService();
  final _fuelStationApi = const FuelStationApi();
  final _stationDistanceService = const StationDistanceService();

  MapLibreMapController? _mapController;
  bool _locating = false;
  bool _mapReady = false;
  bool _initialLoadDone = false;
  bool _stationsLayerCreated = false;

  final Set<String> _registeredMarkerImages = {};

  FuelStation? _selectedStation;
  double? _selectedStationDistanceKm;

  FuelType _selectedFuel = FuelType.gasoline95;

  List<FuelStation> _nearbyStations = [];

  double? _currentLatitude;
  double? _currentLongitude;

  Future<void> _initializeMap() async {
    if (_initialLoadDone || !_mapReady) return;

    _initialLoadDone = true;

    try {
      final position = await _locationService.getCurrentPosition();

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 14.5,
          ),
        ),
      );

      await _loadFuelStations(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (error) {
      debugPrint('❌ Surtio: error inicializando mapa: $error');

      _initialLoadDone = false;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hemos podido obtener tu ubicación.')),
      );
    }
  }

  void _selectLowestPriceStation({
    required List<FuelStation> stations,
    required double latitude,
    required double longitude,
    required FuelType fuelType,
  }) {
    final stationsWithPrice = stations
        .where((station) => station.priceFor(fuelType) != null)
        .toList();

    if (stationsWithPrice.isEmpty) {
      if (mounted) {
        setState(() {
          _selectedStation = null;
          _selectedStationDistanceKm = null;
        });
      }
      return;
    }

    stationsWithPrice.sort(
      (a, b) => a.priceFor(fuelType)!.compareTo(b.priceFor(fuelType)!),
    );

    final selected = stationsWithPrice.first;

    final distanceMeters = Geolocator.distanceBetween(
      latitude,
      longitude,
      selected.latitude,
      selected.longitude,
    );

    if (!mounted) return;

    setState(() {
      _selectedStation = selected;
      _selectedStationDistanceKm = distanceMeters / 1000;
    });
  }

  Future<void> _changeFuel(FuelType fuelType) async {
    if (_selectedFuel == fuelType) return;

    setState(() {
      _selectedFuel = fuelType;
    });

    final latitude = _currentLatitude;
    final longitude = _currentLongitude;

    if (latitude == null || longitude == null || _nearbyStations.isEmpty) {
      return;
    }

    _selectLowestPriceStation(
      stations: _nearbyStations,
      latitude: latitude,
      longitude: longitude,
      fuelType: fuelType,
    );

    await _showStationsOnMap(_nearbyStations, fuelType: fuelType);
  }

  Future<void> _loadFuelStations({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final stations = await _fuelStationApi.fetchStations();

      final nearbyStations = _stationDistanceService.nearbyStations(
        stations: stations,
        latitude: latitude,
        longitude: longitude,
        radiusKm: 20,
      );

      if (!mounted) return;

      setState(() {
        _nearbyStations = nearbyStations;
        _currentLatitude = latitude;
        _currentLongitude = longitude;
      });

      _selectLowestPriceStation(
        stations: nearbyStations,
        latitude: latitude,
        longitude: longitude,
        fuelType: _selectedFuel,
      );

      try {
        await _showStationsOnMap(nearbyStations, fuelType: _selectedFuel);
      } catch (error, stackTrace) {
        debugPrint('❌ ERROR MAPLIBRE: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      debugPrint('⛽ Surtio: ${stations.length} estaciones nacionales');

      debugPrint(
        '📍 Surtio: ${nearbyStations.length} estaciones a menos de 20 km',
      );

      for (final station in nearbyStations.take(5)) {
        debugPrint(
          '⛽ ${station.name} | '
          '${station.municipality} | '
          '${station.gasoline95Price ?? '-'} €/L',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('❌ Surtio: error cargando estaciones: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _goToCurrentLocation() async {
    if (_locating) return;

    setState(() => _locating = true);

    try {
      final position = await _locationService.getCurrentPosition();

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 14.5,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hemos podido obtener tu ubicación.')),
      );
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  Future<Uint8List> _createStationMarkerImage(
    String priceLabel,
    String fuelLabel, {
    bool recommended = false,
  }) async {
    const width = 164.0;
    const bodyHeight = 68.0;
    const height = 88.0;
    const pixelRatio = 2.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.scale(pixelRatio);

    final backgroundPaint = Paint()..color = const Color(0xFF081923);

    final borderPaint = Paint()
      ..color = recommended ? const Color(0xFF32F5A6) : const Color(0xFF718791)
      ..style = PaintingStyle.stroke
      ..strokeWidth = recommended ? 3.5 : 2.5;

    final bodyRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(2, 2, width - 4, bodyHeight - 4),
      const Radius.circular(22),
    );

    canvas.drawRRect(bodyRect, backgroundPaint);
    canvas.drawRRect(bodyRect, borderPaint);

    final pointerPath = Path()
      ..moveTo(68, 64)
      ..lineTo(width / 2, 84)
      ..lineTo(96, 64)
      ..close();

    canvas.drawPath(pointerPath, backgroundPaint);

    final pointerBorderPath = Path()
      ..moveTo(68, 64)
      ..lineTo(width / 2, 84)
      ..lineTo(96, 64);

    canvas.drawPath(pointerBorderPath, borderPaint);

    final badgePaint = Paint()
      ..color = recommended ? const Color(0xFF32F5A6) : const Color(0xFFF6FAFC);

    final badgeRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(14, 15, 40, 38),
      const Radius.circular(12),
    );

    canvas.drawRRect(badgeRect, badgePaint);

    final fuelPainter = TextPainter(
      text: TextSpan(
        text: fuelLabel,
        style: TextStyle(
          color: const Color(0xFF081923),
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    fuelPainter.paint(
      canvas,
      Offset(34 - fuelPainter.width / 2, 34 - fuelPainter.height / 2),
    );

    final pricePainter = TextPainter(
      text: TextSpan(
        text: priceLabel,
        style: const TextStyle(
          color: Color(0xFFF6FAFC),
          fontSize: 25,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    pricePainter.paint(
      canvas,
      Offset(104 - pricePainter.width / 2, 34 - pricePainter.height / 2),
    );

    final picture = recorder.endRecording();

    final image = await picture.toImage(
      (width * pixelRatio).round(),
      (height * pixelRatio).round(),
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw StateError('No se pudo generar el marcador de Surtio.');
    }

    return byteData.buffer.asUint8List();
  }

  Future<String?> _ensureMarkerImage(
    MapLibreMapController controller,
    double? price,
    FuelType fuelType,
  ) async {
    if (price == null) return null;

    final priceLabel = price.toStringAsFixed(3).replaceAll('.', ',');

    final markerId =
        'surtio-marker-${fuelType.name}-${price.toStringAsFixed(3).replaceAll('.', '-')}';

    if (!_registeredMarkerImages.contains(markerId)) {
      final markerImage = await _createStationMarkerImage(
        priceLabel,
        fuelType.markerLabel,
      );

      await controller.addImage(markerId, markerImage);

      _registeredMarkerImages.add(markerId);
    }

    return markerId;
  }

  Future<void> _showStationsOnMap(
    List<FuelStation> stations, {
    required FuelType fuelType,
  }) async {
    final controller = _mapController;

    if (controller == null || stations.isEmpty) {
      return;
    }

    const sourceId = 'fuel-stations';
    const markerLayerId = 'fuel-stations-markers';

    final features = <Map<String, dynamic>>[];

    for (final station in stations) {
      final price = station.priceFor(fuelType);

      if (price == null) {
        continue;
      }

      final markerImage = await _ensureMarkerImage(controller, price, fuelType);

      if (markerImage == null) {
        continue;
      }

      features.add({
        'type': 'Feature',
        'properties': {
          'id': station.id,
          'name': station.name,
          'markerImage': markerImage,
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [station.longitude, station.latitude],
        },
      });
    }

    final geoJson = {'type': 'FeatureCollection', 'features': features};

    if (_stationsLayerCreated) {
      await controller.setGeoJsonSource(sourceId, geoJson);

      debugPrint('🔄 Surtio: ${features.length} estaciones actualizadas');

      return;
    }

    await controller.addGeoJsonSource(sourceId, geoJson);

    await controller.addSymbolLayer(
      sourceId,
      markerLayerId,
      const SymbolLayerProperties(
        iconImage: [Expressions.get, 'markerImage'],
        iconSize: 0.90,
        iconAnchor: 'bottom',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
    );

    _stationsLayerCreated = true;

    debugPrint('🗺️ Surtio: ${features.length} estaciones pintadas');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MapHeader(
          onLocationPressed: _goToCurrentLocation,
          selectedFuel: _selectedFuel,
          onFuelSelected: _changeFuel,
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: MapLibreMap(
                    styleString: MapConfig.styleUrl,
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(
                        MapConfig.initialLatitude,
                        MapConfig.initialLongitude,
                      ),
                      zoom: MapConfig.initialZoom,
                    ),
                    compassEnabled: false,
                    rotateGesturesEnabled: false,
                    myLocationEnabled: true,
                    myLocationTrackingMode: MyLocationTrackingMode.none,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    onStyleLoadedCallback: () {
                      _mapReady = true;
                      _initializeMap();
                    },
                  ),
                ),
                if (_selectedStation != null &&
                    _selectedStationDistanceKm != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -10,
                    child: _BestStationCard(
                      station: _selectedStation!.name,
                      address: _selectedStation!.address,
                      price: _selectedStation!
                          .priceFor(_selectedFuel)!
                          .toStringAsFixed(3)
                          .replaceAll('.', ','),
                      distance:
                          '${_selectedStationDistanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km',
                      fillCost:
                          '${(_selectedStation!.priceFor(_selectedFuel)! * 40).toStringAsFixed(2).replaceAll('.', ',')} €',
                      fuelType: _selectedFuel,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BestStationCard extends StatelessWidget {
  const _BestStationCard({
    required this.station,
    required this.address,
    required this.price,
    required this.distance,
    required this.fillCost,
    required this.fuelType,
  });

  final String station;
  final String address;
  final String price;
  final String distance;
  final String fillCost;
  final FuelType fuelType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.98),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
        border: Border.all(color: const Color(0xFF245064), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabecera
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x26FFE600),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 17,
                      color: Color(0xFFFFE600),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Precio más bajo cerca de ti',
                      style: TextStyle(
                        color: Color(0xFFFFE600),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.route_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                distance,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Gasolinera
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6FAFC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.local_gas_station_rounded,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

          const SizedBox(height: 16),

          // Precio
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 3),
                child: Text(
                  '€/L',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Ahorro
          Row(
            children: [
              const Icon(
                Icons.local_gas_station_rounded,
                color: AppColors.primary,
                size: 19,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '40 L te costarían $fillCost',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Acciones
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      backgroundColor: const Color(0xFF102A35),
                      side: const BorderSide(color: Color(0xFF1E3D49)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Ver detalles',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.navigation_rounded, size: 19),
                    label: const Text(
                      'Ir ahora',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
