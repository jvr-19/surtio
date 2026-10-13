import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class PriceFreshness extends StatelessWidget {
  const PriceFreshness({super.key, required this.queriedAt});
  final DateTime? queriedAt;

  @override
  Widget build(BuildContext context) {
    final time = queriedAt?.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return Text(
      time == null
          ? 'Precios oficiales · fecha de consulta no disponible'
          : 'Consulta: ${two(time.day)}/${two(time.month)} ${two(time.hour)}:${two(time.minute)} · Confirma el precio al repostar.',
      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
    );
  }
}
