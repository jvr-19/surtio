import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/map/map_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/location/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _selectedFuel = '95';

  static const _fuels = ['95', 'Diésel', '98'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(),
          _buildFuelSelector(),
          const SizedBox(height: 14),
          const Expanded(child: _MapPlaceholder()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_gas_station_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Surtio',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                Text(
                  'Reposta mejor.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _HeaderButton(icon: Icons.search_rounded, onPressed: () {}),
          const SizedBox(width: 8),
          _HeaderButton(icon: Icons.tune_rounded, onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildFuelSelector() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _fuels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final fuel = _fuels[index];
          final selected = fuel == _selectedFuel;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFuel = fuel;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                fuel,
                style: TextStyle(
                  color: selected
                      ? AppColors.background
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 21, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatefulWidget {
  const _MapPlaceholder();

  @override
  State<_MapPlaceholder> createState() => _MapPlaceholderState();
}

class _MapPlaceholderState extends State<_MapPlaceholder> {
  final _locationService = const LocationService();

  MapLibreMapController? _mapController;
  bool _locating = false;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),

          const Positioned(
            top: 95,
            left: 45,
            child: _PriceMarker(price: '1,429'),
          ),

          const Positioned(
            top: 180,
            right: 55,
            child: _PriceMarker(price: '1,389', best: true),
          ),

          const Positioned(
            top: 275,
            left: 120,
            child: _PriceMarker(price: '1,409'),
          ),

          Positioned(
            left: 14,
            right: 14,
            bottom: 18,
            child: _BestStationCard(
              station: 'Plenergy',
              price: '1,389',
              distance: '1,8 km',
              time: '4 min',
              fillCost: '55,56 €',
            ),
          ),

          Positioned(
            right: 16,
            bottom: 190,
            child: FloatingActionButton.small(
              heroTag: 'location',
              elevation: 0,
              backgroundColor: AppColors.surfaceElevated,
              foregroundColor: AppColors.primary,
              onPressed: _locating ? null : _goToCurrentLocation,
              child: _locating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceMarker extends StatelessWidget {
  const _PriceMarker({required this.price, this.best = false});

  final String price;
  final bool best;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: best ? AppColors.primary : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: best ? AppColors.primary : AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '$price €',
        style: TextStyle(
          color: best ? AppColors.background : AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _BestStationCard extends StatelessWidget {
  const _BestStationCard({
    required this.station,
    required this.price,
    required this.distance,
    required this.time,
    required this.fillCost,
  });

  final String station;
  final String price;
  final String distance;
  final String time;
  final String fillCost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: 6),
              Text(
                'REPOSTARÍA AQUÍ',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$distance  ·  $time',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: price,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const TextSpan(
                      text: ' €/L',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_gas_station_outlined,
                  color: AppColors.textSecondary,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Text(
                  '40 L te costarían $fillCost',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: const Text(
                'Ir ahora',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
