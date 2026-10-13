import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Generic station symbol; no bundled brand images are available.
class StationLogo extends StatelessWidget {
  const StationLogo({super.key, required this.stationName, this.size = 48});
  final String stationName;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * 0.14),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F8F9),
      borderRadius: BorderRadius.circular(size * 0.24),
    ),
    child: Icon(
      Icons.local_gas_station_rounded,
      color: AppColors.primary,
      size: size * 0.52,
    ),
  );
}
