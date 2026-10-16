import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/theme/app_colors.dart';
import 'widgets/map_header.dart';
import '../../../core/location/search_area.dart';
import '../../../shared/widgets/price_freshness.dart';
import '../../../core/location/area_picker.dart';
import '../../../core/stations/station_actions.dart';
import '../../../core/stations/fuel_selection.dart';
import '../../../core/map/map_config.dart';
import '../data/models/fuel_station.dart';
import '../data/services/fuel_station_api.dart';
import '../domain/services/station_distance_service.dart';
import '../../station/presentation/station_detail_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key, this.onMapCreated});
  final ValueChanged<MapLibreMapController>? onMapCreated;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: _MapContent(onMapCreated: onMapCreated),
    );
  }
}

class _MapContent extends StatelessWidget {
  const _MapContent({this.onMapCreated});
  final ValueChanged<MapLibreMapController>? onMapCreated;

  @override
  Widget build(BuildContext context) {
    return _MapPlaceholder(onMapCreated: onMapCreated);
  }
}

class _MapPlaceholder extends StatefulWidget {
  const _MapPlaceholder({this.onMapCreated});
  final ValueChanged<MapLibreMapController>? onMapCreated;

  @override
  State<_MapPlaceholder> createState() => _MapPlaceholderState();
}

class _MapPlaceholderState extends State<_MapPlaceholder> {
  final _area = SearchAreaController.instance;
  final _fuelSelection = FuelSelection.instance;
  bool _locationAllowed = false;
  int _loadRequest = 0;
  bool _stationsLoading = false;
  String? _stationError;
  final _fuelStationApi = const FuelStationApi();
  final _stationDistanceService = const StationDistanceService();

  MapLibreMapController? _mapController;
  bool _locating = false;
  bool _mapReady = false;
  bool _initialLoadDone = false;
  bool _stationsLayerCreated = false;
  Future<void> _renderQueue = Future.value();
  int _renderRevision = 0;
  final Map<int, PointerDownEvent> _mapPointers = {};
  bool _multiTouch = false;
  int _tapRequest = 0;

  final Set<String> _registeredMarkerImages = {};

  String? _userSelectedStationId;
  bool _usingSavedPrices = false;
  FuelStation? _selectedStation;
  double? _selectedStationDistanceKm;

  FuelType _selectedFuel = FuelType.gasoline95;

  List<FuelStation> _nearbyStations = [];

  DateTime? _queriedAt;
  double? _currentLatitude;
  double? _currentLongitude;

  @override
  void initState() {
    super.initState();
    _area.addListener(_onAreaChanged);
    _fuelSelection.addListener(_onFuelChanged);
    _selectedFuel = _fuelSelection.value;
    _fuelSelection.initialize();
  }

  @override
  void dispose() {
    _renderRevision++;
    _mapController?.onFeatureTapped.remove(_onStationTapped);
    _area.removeListener(_onAreaChanged);
    _fuelSelection.removeListener(_onFuelChanged);
    super.dispose();
  }

  void _onStationTapped(
    math.Point<double> point,
    LatLng coordinates,
    String id,
    String layer,
    Annotation? annotation,
  ) {
    if (layer == 'fuel-stations-markers') _selectStation(id);
  }

  void _selectStation(String id) {
    if (!mounted || _stationsLoading) return;
    final matches = _nearbyStations.where(
      (station) => station.id == id && station.priceFor(_selectedFuel) != null,
    );
    if (matches.isEmpty) return;
    final station = matches.first;
    final area = _area.area;
    setState(() {
      _userSelectedStationId = station.id;
      _selectedStation = station;
      _selectedStationDistanceKm =
          Geolocator.distanceBetween(
            area.latitude,
            area.longitude,
            station.latitude,
            station.longitude,
          ) /
          1000;
    });
  }

  void _mapPointerDown(PointerDownEvent event) {
    _mapPointers[event.pointer] = event;
    if (_mapPointers.length > 1) _multiTouch = true;
  }

  void _mapPointerCancel(PointerCancelEvent event) {
    _mapPointers.remove(event.pointer);
    if (_mapPointers.isEmpty) _multiTouch = false;
  }

  void _mapPointerUp(PointerUpEvent event) {
    final down = _mapPointers.remove(event.pointer);
    final tap =
        down != null &&
        !_multiTouch &&
        (down.localPosition - event.localPosition).distance <= 12 &&
        event.timeStamp - down.timeStamp < const Duration(seconds: 1);
    if (_mapPointers.isEmpty) _multiTouch = false;
    if (tap) _selectRenderedStation(event.localPosition);
  }

  Future<void> _selectRenderedStation(Offset point) async {
    final controller = _mapController;
    if (controller == null || _stationsLoading || !_stationsLayerCreated) {
      return;
    }
    final request = ++_tapRequest;
    final revision = _renderRevision;
    final scale = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? View.of(context).devicePixelRatio
        : 1.0;
    try {
      final features = await controller.queryRenderedFeatures(
        math.Point(point.dx * scale, point.dy * scale),
        ['fuel-stations-markers'],
        null,
      );
      if (!mounted ||
          request != _tapRequest ||
          revision != _renderRevision ||
          features.isEmpty) {
        return;
      }
      final feature = features.first;
      if (feature is Map && feature['properties'] is Map) {
        final id = (feature['properties'] as Map)['id'];
        if (id != null) _selectStation(id.toString());
      }
    } catch (_) {
      // A map hit-test failure must leave list navigation available.
    }
  }

  void _onFuelChanged() {
    if (mounted) _changeFuel(_fuelSelection.value);
  }

  void _onAreaChanged() {
    if (_mapReady && mounted) _showArea();
  }

  Future<void> _initializeMap() async {
    if (_initialLoadDone || !_mapReady) return;
    _initialLoadDone = true;
    await _area.initialize();
    if (mounted) await _showArea();
  }

  Future<void> _showArea({bool refresh = false}) async {
    final request = ++_loadRequest;
    final area = _area.area;
    setState(() {
      _locationAllowed = area.isDevice;
      _stationsLoading = true;
      _stationError = null;
      if (!refresh) {
        _userSelectedStationId = null;
        _selectedStation = null;
        _selectedStationDistanceKm = null;
      }
    });
    try {
      if (!refresh) {
        await _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(area.latitude, area.longitude),
              zoom: _area.radiusKm <= 5
                  ? 13
                  : _area.radiusKm <= 10
                  ? 12.5
                  : _area.radiusKm <= 20
                  ? 11.5
                  : 10.5,
            ),
          ),
        );
      }
      if (!mounted || request != _loadRequest) return;
      await _loadFuelStations(
        latitude: area.latitude,
        longitude: area.longitude,
        requestId: request,
        refresh: refresh,
      );
    } catch (_) {
      if (!mounted || request != _loadRequest) return;
      setState(() => _stationError = 'No se pudieron cargar los precios.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No se pudieron cargar los precios. Comprueba la conexión.',
          ),
          action: SnackBarAction(label: 'Reintentar', onPressed: _showArea),
        ),
      );
    } finally {
      if (mounted && request == _loadRequest) {
        setState(() => _stationsLoading = false);
      }
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

    final chosen = stationsWithPrice.where(
      (s) => s.id == _userSelectedStationId,
    );
    final selected = chosen.isEmpty ? stationsWithPrice.first : chosen.first;

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
    _fuelSelection.select(fuelType);

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

    try {
      await _showStationsOnMap(_nearbyStations, fuelType: fuelType);
    } catch (_) {
      if (mounted) {
        setState(
          () => _stationError =
              'No se pudo actualizar el mapa. Puedes consultar Cerca.',
        );
      }
    }
  }

  Future<void> _loadFuelStations({
    required double latitude,
    required double longitude,
    required int requestId,
    bool refresh = false,
  }) async {
    try {
      final stations = await _fuelStationApi.fetchStations(
        forceRefresh: refresh,
      );

      final nearbyStations = _stationDistanceService.nearbyStations(
        stations: stations,
        latitude: latitude,
        longitude: longitude,
        radiusKm: _area.radiusKm,
      );

      if (!mounted || requestId != _loadRequest) return;

      setState(() {
        _queriedAt = FuelStationApi.lastUpdated;
        _usingSavedPrices = FuelStationApi.usingSavedPrices;
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
        if (kDebugMode) {
          debugPrint('Error al dibujar estaciones: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error al cargar estaciones: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      rethrow;
    }
  }

  Future<void> _goToCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      await _area.useDeviceLocation();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Ubicación no disponible. Puedes elegir una zona.',
          ),
          action: SnackBarAction(
            label: 'Elegir zona',
            onPressed: () => pickSearchArea(context),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
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
    image.dispose();
    picture.dispose();

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

      if (!mounted) return null;
      await controller.addImage(markerId, markerImage);

      _registeredMarkerImages.add(markerId);
    }

    return markerId;
  }

  Future<void> _showStationsOnMap(
    List<FuelStation> stations, {
    required FuelType fuelType,
  }) {
    final revision = ++_renderRevision;
    final next = _renderQueue.then(
      (_) => _renderStations(stations, fuelType: fuelType, revision: revision),
    );
    _renderQueue = next.catchError((Object _) {});
    return next;
  }

  Future<void> _renderStations(
    List<FuelStation> stations, {
    required FuelType fuelType,
    required int revision,
  }) async {
    if (!mounted || revision != _renderRevision) return;
    final controller = _mapController;

    if (controller == null) {
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

      if (!mounted || revision != _renderRevision) return;
      if (markerImage == null) {
        continue;
      }

      features.add({
        'type': 'Feature',
        'id': station.id,
        'properties': {
          'id': station.id,
          'name': station.name,
          'markerImage': markerImage,
          'price': price,
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
        iconAllowOverlap: false,
        iconIgnorePlacement: false,
        iconPadding: 4,
        symbolSortKey: [Expressions.get, 'price'],
      ),
    );

    _stationsLayerCreated = true;
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Zona: ${_area.area.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              PopupMenuButton<double>(
                tooltip: 'Radio de búsqueda',
                initialValue: _area.radiusKm,
                onSelected: _area.selectRadius,
                itemBuilder: (_) => [
                  for (final radius in SearchAreaController.radiusOptions)
                    PopupMenuItem(
                      value: radius,
                      child: Text('${radius.toInt()} km'),
                    ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('${_area.radiusKm.toInt()} km'),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: PriceFreshness(
                  queriedAt: _queriedAt,
                  usingSavedPrices: _usingSavedPrices,
                ),
              ),
              IconButton(
                tooltip: 'Actualizar precios',
                onPressed: _stationsLoading
                    ? null
                    : () => _showArea(refresh: true),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
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
                  child: Listener(
                    onPointerDown: _mapPointerDown,
                    onPointerUp: _mapPointerUp,
                    onPointerCancel: _mapPointerCancel,
                    child: MapLibreMap(
                      styleString: MapConfig.styleUrl,
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(
                          MapConfig.initialLatitude,
                          MapConfig.initialLongitude,
                        ),
                        zoom: MapConfig.initialZoom,
                      ),
                      attributionButtonPosition:
                          AttributionButtonPosition.topRight,
                      compassEnabled: false,
                      rotateGesturesEnabled: false,
                      myLocationEnabled: _locationAllowed,
                      myLocationTrackingMode: MyLocationTrackingMode.none,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        controller.onFeatureTapped.add(_onStationTapped);
                        widget.onMapCreated?.call(controller);
                      },
                      onStyleLoadedCallback: () {
                        _mapReady = true;
                        _initializeMap();
                      },
                    ),
                  ),
                ),
                if (_stationsLoading)
                  const Positioned(
                    top: 12,
                    left: 20,
                    right: 20,
                    child: LinearProgressIndicator(),
                  ),
                if (_mapReady &&
                    !_stationsLoading &&
                    (_stationError != null ||
                        _nearbyStations
                            .where((s) => s.priceFor(_selectedFuel) != null)
                            .isEmpty))
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _stationError ??
                                  'No hay precios de este combustible a ${_area.radiusKm.toInt()} km de la zona.',
                            ),
                            TextButton(
                              onPressed: _stationError == null
                                  ? () => pickSearchArea(context)
                                  : _showArea,
                              child: Text(
                                _stationError == null
                                    ? 'Elegir otra zona'
                                    : 'Reintentar',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_selectedStation != null &&
                    _selectedStationDistanceKm != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.38,
                      ),
                      child: SingleChildScrollView(
                        child: _BestStationCard(
                          isLowestPrice: !_nearbyStations.any(
                            (s) =>
                                s.priceFor(_selectedFuel) != null &&
                                s.priceFor(_selectedFuel)! <
                                    _selectedStation!.priceFor(_selectedFuel)!,
                          ),
                          queriedAt: _queriedAt,
                          usingSavedPrices: _usingSavedPrices,
                          fuelStation: _selectedStation!,
                          distanceKm: _selectedStationDistanceKm!,
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
    required this.fuelStation,
    this.queriedAt,
    this.usingSavedPrices = false,
    required this.isLowestPrice,
    required this.distanceKm,
    required this.station,
    required this.address,
    required this.price,
    required this.distance,
    required this.fillCost,
    required this.fuelType,
  });

  final bool isLowestPrice;
  final FuelStation fuelStation;
  final DateTime? queriedAt;
  final bool usingSavedPrices;
  final double distanceKm;
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
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x26FFE600),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 17,
                        color: Color(0xFFFFE600),
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isLowestPrice
                              ? 'Más barata en la zona'
                              : 'Estación seleccionada',
                          style: TextStyle(
                            color: Color(0xFFFFE600),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.near_me_outlined,
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
                  height: 50 * MediaQuery.textScalerOf(context).scale(1),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StationDetailScreen(
                            station: fuelStation,
                            queriedAt: queriedAt,
                            usingSavedPrices: usingSavedPrices,
                            distanceKm: distanceKm,
                            initialFuel: fuelType,
                          ),
                        ),
                      );
                    },
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
                    onPressed: () =>
                        StationActions.navigate(context, fuelStation),
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
