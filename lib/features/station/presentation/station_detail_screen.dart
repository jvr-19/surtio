import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../map/data/models/fuel_station.dart';
import '../data/models/fuel_price_history_point.dart';
import '../data/services/fuel_price_history_service.dart';
import 'widgets/price_history_chart.dart';

class StationDetailScreen extends StatefulWidget {
  const StationDetailScreen({
    super.key,
    required this.station,
    required this.distanceKm,
    this.initialFuel = FuelType.gasoline95,
  });

  final FuelStation station;
  final double distanceKm;
  final FuelType initialFuel;

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  late FuelType _selectedFuel;

  final _historyService = FuelPriceHistoryService();

  List<FuelPriceHistoryPoint> _historyPoints = [];
  FuelPriceHistoryPeriod _historyPeriod = FuelPriceHistoryPeriod.sevenDays;
  bool _historyLoading = true;
  String? _historyError;
  int _historyRequestId = 0;

  List<FuelType> get _availableFuels {
    return FuelType.values
        .where((fuel) => widget.station.priceFor(fuel) != null)
        .toList();
  }

  @override
  void initState() {
    super.initState();

    final availableFuels = _availableFuels;

    if (availableFuels.isEmpty) {
      _selectedFuel = widget.initialFuel;
      _historyLoading = false;
      return;
    }

    _selectedFuel = widget.station.priceFor(widget.initialFuel) != null
        ? widget.initialFuel
        : availableFuels.first;

    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final requestId = ++_historyRequestId;
    final requestedFuel = _selectedFuel;
    final requestedPeriod = _historyPeriod;

    setState(() {
      _historyLoading = true;
      _historyError = null;
    });

    try {
      final points = await _historyService.fetchHistory(
        station: widget.station,
        fuelType: requestedFuel,
        period: requestedPeriod,
      );

      if (!mounted || requestId != _historyRequestId) {
        return;
      }

      setState(() {
        _historyPoints = points;
        _historyLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _historyRequestId) {
        return;
      }

      setState(() {
        _historyPoints = [];
        _historyLoading = false;
        _historyError = 'No se pudo cargar el histórico';
      });
    }
  }

  @override
  void dispose() {
    _historyService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final station = widget.station;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 14),

              // Más adelante aquí irá la foto real de la estación.
              const _StationHero(),

              const SizedBox(height: 18),

              _StationIdentity(station: station, distanceKm: widget.distanceKm),

              const SizedBox(height: 22),

              _FuelPriceSelector(
                station: station,
                selectedFuel: _selectedFuel,
                onSelected: (fuel) {
                  if (fuel == _selectedFuel) {
                    return;
                  }

                  setState(() {
                    _selectedFuel = fuel;
                    _historyPoints = [];
                  });

                  _loadHistory();
                },
              ),

              const SizedBox(height: 18),

              _PrimaryButton(
                label: 'Ir ahora',
                icon: Icons.navigation_rounded,
                onPressed: () {
                  // Próximamente: abrir navegación.
                },
              ),

              const SizedBox(height: 14),

              const _ActionButtons(),

              if (station.schedule.isNotEmpty) ...[
                const SizedBox(height: 24),
                _ScheduleSection(schedule: station.schedule),
              ],

              const SizedBox(height: 28),

              _PriceHistorySection(
                fuelType: _selectedFuel,
                selectedPeriod: _historyPeriod,
                points: _historyPoints,
                loading: _historyLoading,
                error: _historyError,
                onPeriodSelected: (period) {
                  if (period == _historyPeriod) {
                    return;
                  }
                  setState(() {
                    _historyPeriod = period;
                    _historyPoints = [];
                  });
                  _loadHistory();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TopButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const Spacer(),
        _TopButton(icon: Icons.favorite_border_rounded, onTap: () {}),
        const SizedBox(width: 10),
        _TopButton(icon: Icons.ios_share_rounded, onTap: () {}),
      ],
    );
  }
}

class _TopButton extends StatelessWidget {
  const _TopButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, color: AppColors.textPrimary, size: 23),
      ),
    );
  }
}

class _StationHero extends StatelessWidget {
  const _StationHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 175,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2A36), Color(0xFF071820)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -42,
            child: Icon(
              Icons.local_gas_station_rounded,
              size: 220,
              color: AppColors.primary.withValues(alpha: 0.045),
            ),
          ),
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.local_gas_station_rounded,
                color: AppColors.primary,
                size: 39,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StationIdentity extends StatelessWidget {
  const _StationIdentity({required this.station, required this.distanceKm});

  final FuelStation station;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    final location = station.address.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7F8),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(
            Icons.local_gas_station_rounded,
            color: AppColors.primary,
            size: 31,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                station.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              if (location.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  location,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(
                    Icons.route_rounded,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FuelPriceSelector extends StatelessWidget {
  const _FuelPriceSelector({
    required this.station,
    required this.selectedFuel,
    required this.onSelected,
  });

  final FuelStation station;
  final FuelType selectedFuel;
  final ValueChanged<FuelType> onSelected;

  @override
  Widget build(BuildContext context) {
    final fuels = FuelType.values
        .where((fuel) => station.priceFor(fuel) != null)
        .toList();

    if (fuels.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: fuels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final fuel = fuels[index];
          final price = station.priceFor(fuel)!;
          final selected = fuel == selectedFuel;

          return InkWell(
            onTap: () => onSelected(fuel),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 122,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price.toStringAsFixed(3).replaceAll('.', ','),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 1),
                        child: Text(
                          '€/L',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    fuel.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.backgroundDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 21),
            const SizedBox(width: 9),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.favorite_border_rounded,
            label: 'Guardar',
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.share_rounded,
            label: 'Compartir',
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.route_rounded,
            label: 'Ruta',
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 23),
            const SizedBox(height: 7),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({required this.schedule});

  final String schedule;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.schedule_rounded,
          color: AppColors.textPrimary,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Horario  ',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: schedule,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _PriceHistorySection extends StatelessWidget {
  const _PriceHistorySection({
    required this.fuelType,
    required this.selectedPeriod,
    required this.points,
    required this.loading,
    required this.error,
    required this.onPeriodSelected,
  });

  final FuelType fuelType;
  final FuelPriceHistoryPeriod selectedPeriod;
  final List<FuelPriceHistoryPoint> points;
  final bool loading;
  final String? error;
  final ValueChanged<FuelPriceHistoryPeriod> onPeriodSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evolución del precio (${fuelType.fullName})',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: FuelPriceHistoryPeriod.values.map((period) {
              final selected = period == selectedPeriod;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(period.label),
                  selected: selected,
                  onSelected: (_) => onPeriodSelected(period),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: selected
                        ? AppColors.background
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 200,
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Text(
          error!,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    if (points.length < 2) {
      return const Center(
        child: Text(
          'No hay suficientes datos históricos',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return PriceHistoryChart(points: points);
  }
}
