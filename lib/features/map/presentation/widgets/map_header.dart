import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/fuel_station.dart';

class MapHeader extends StatelessWidget {
  const MapHeader({
    super.key,
    required this.onLocationPressed,
    required this.selectedFuel,
    required this.onFuelSelected,
  });

  final VoidCallback onLocationPressed;
  final FuelType selectedFuel;
  final ValueChanged<FuelType> onFuelSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.local_gas_station_rounded,
                  color: AppColors.backgroundDeep,
                  size: 26,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Surtio',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Reposta mejor.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onLocationPressed,
                tooltip: 'Usar mi ubicación',
                icon: const Icon(Icons.my_location_rounded),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _FuelSelector(
            selectedFuel: selectedFuel,
            onFuelSelected: onFuelSelected,
          ),
        ],
      ),
    );
  }
}

class _FuelSelector extends StatelessWidget {
  const _FuelSelector({
    required this.selectedFuel,
    required this.onFuelSelected,
  });

  final FuelType selectedFuel;
  final ValueChanged<FuelType> onFuelSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FuelType.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final fuel = FuelType.values[index];

          return _FuelChip(
            label: fuel.label,
            semanticLabel: fuel.fullName,
            selected: fuel == selectedFuel,
            onTap: () => onFuelSelected(fuel),
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
