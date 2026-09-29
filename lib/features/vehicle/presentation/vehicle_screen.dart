import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../map/data/models/fuel_station.dart';
import '../data/models/vehicle_profile.dart';
import '../data/repositories/vehicle_profile_repository.dart';
import 'vehicle_form_screen.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key, this.repository});

  final VehicleProfileRepository? repository;

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  late final VehicleProfileRepository _repository;
  VehicleProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? SharedPreferencesVehicleProfileRepository();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _repository.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  Future<void> _openEditor() async {
    final updatedProfile = await Navigator.of(context).push<VehicleProfile>(
      MaterialPageRoute(
        builder: (_) => VehicleFormScreen(initialProfile: _profile),
      ),
    );
    if (updatedProfile == null || !mounted) {
      return;
    }

    try {
      await _repository.save(updatedProfile);
      if (!mounted) {
        return;
      }
      setState(() => _profile = updatedProfile);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el coche.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
                  sliver: SliverList.list(
                    children: [
                      const _VehicleHeader(),
                      const SizedBox(height: 24),
                      if (_profile == null)
                        _EmptyVehicleState(onAdd: _openEditor)
                      else
                        _VehicleDashboard(
                          profile: _profile!,
                          onEdit: _openEditor,
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _VehicleHeader extends StatelessWidget {
  const _VehicleHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _MintIcon(icon: Icons.directions_car_rounded, size: 52),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mi coche',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Tu repostaje, más inteligente.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyVehicleState extends StatelessWidget {
  const _EmptyVehicleState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 26),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.directions_car_outlined,
              color: AppColors.primary,
              size: 42,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Añade tu coche',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Guarda su consumo y depósito para calcular una autonomía '
            'teórica y preparar futuras estimaciones de repostaje.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Añadir coche',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleDashboard extends StatelessWidget {
  const _VehicleDashboard({required this.profile, required this.onEdit});

  final VehicleProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VehicleCard(profile: profile, onTap: onEdit),
        const SizedBox(height: 14),
        _VehicleStats(profile: profile),
        const SizedBox(height: 26),
        const _SectionTitle(
          icon: Icons.bar_chart_rounded,
          title: 'Precio recomendado',
        ),
        const SizedBox(height: 10),
        const _FutureStateCard(
          icon: Icons.insights_rounded,
          title: 'Recomendación en preparación',
          description:
              'Estará disponible cuando tengamos suficiente histórico real '
              'para comparar los precios de tu combustible.',
        ),
        const SizedBox(height: 26),
        const _SectionTitle(
          icon: Icons.my_location_rounded,
          title: 'Tu gasolinera habitual',
        ),
        const SizedBox(height: 10),
        const _FutureStateCard(
          icon: Icons.local_gas_station_outlined,
          title: 'Aún no has elegido una gasolinera habitual',
          description:
              'Más adelante podrás asignarla para consultar sus precios con '
              'mayor rapidez.',
        ),
        const SizedBox(height: 26),
        const _SectionTitle(
          icon: Icons.notifications_none_rounded,
          title: 'Alertas de precio',
        ),
        const SizedBox(height: 10),
        const _AlertsComingSoonCard(),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.profile, required this.onTap});

  final VehicleProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = profile.variant == null
        ? profile.fuelType.fullName
        : '${profile.variant} · ${profile.fuelType.fullName}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 66,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: AppColors.primary,
                  size: 38,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleStats extends StatelessWidget {
  const _VehicleStats({required this.profile});

  final VehicleProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: _formatDecimal(profile.averageConsumption),
            unit: 'L/100 km',
            label: 'Consumo medio',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: _formatDecimal(profile.tankCapacity),
            unit: 'L',
            label: 'Capacidad',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '~${profile.theoreticalRangeKm.round()}',
            unit: 'km',
            label: 'Autonomía teórica',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.unit,
    required this.label,
  });

  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 106,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: _cardDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 2,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 23),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _FutureStateCard extends StatelessWidget {
  const _FutureStateCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.primary, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
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

class _AlertsComingSoonCard extends StatelessWidget {
  const _AlertsComingSoonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avísame cuando baje de un precio',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Próximamente',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(value: false, onChanged: null),
        ],
      ),
    );
  }
}

class _MintIcon extends StatelessWidget {
  const _MintIcon({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Icon(icon, color: AppColors.primary, size: size * 0.8),
    );
  }
}

BoxDecoration _cardDecoration({double radius = 18}) => BoxDecoration(
  color: AppColors.surfaceElevated.withValues(alpha: 0.72),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: AppColors.border),
);

String _formatDecimal(double value) {
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return text.replaceAll('.', ',');
}
