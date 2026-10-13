import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class StationLogo extends StatelessWidget {
  const StationLogo({super.key, required this.stationName, this.size = 48});

  final String stationName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = _assetForStation(stationName);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F9),
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: asset != null
          ? Image.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _fallbackIcon(),
            )
          : _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() {
    return Icon(
      Icons.local_gas_station_rounded,
      color: AppColors.primary,
      size: size * 0.52,
    );
  }

  String? _assetForStation(String name) {
    final normalized = name
        .toUpperCase()
        .trim()
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U');

    if (normalized.contains('DISA')) {
      return 'assets/images/stations/disa.png';
    }

    if (normalized.contains('SHELL')) {
      return 'assets/images/stations/shell.png';
    }

    if (normalized.contains('REPSOL')) {
      return 'assets/images/stations/repsol.png';
    }

    if (normalized.contains('CEPSA') || normalized.contains('MOEVE')) {
      return 'assets/images/stations/moeve.png';
    }

    if (normalized.contains('BP')) {
      return 'assets/images/stations/bp.png';
    }

    if (normalized.contains('PLENERGY') || normalized.contains('PLENOIL')) {
      return 'assets/images/stations/plenergy.png';
    }

    return null;
  }
}
