import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../map/data/models/fuel_station.dart';
import '../data/models/vehicle_profile.dart';

class VehicleFormScreen extends StatefulWidget {
  const VehicleFormScreen({super.key, this.initialProfile});

  final VehicleProfile? initialProfile;

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _variantController;
  late final TextEditingController _consumptionController;
  late final TextEditingController _capacityController;
  late FuelType _fuelType;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _variantController = TextEditingController(text: profile?.variant ?? '');
    _consumptionController = TextEditingController(
      text: profile == null ? '' : _formatNumber(profile.averageConsumption),
    );
    _capacityController = TextEditingController(
      text: profile == null ? '' : _formatNumber(profile.tankCapacity),
    );
    _fuelType = profile?.fuelType ?? FuelType.gasoline95;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _variantController.dispose();
    _consumptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialProfile != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(editing ? 'Editar coche' : 'Añadir coche'),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              const _FormIntro(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: _decoration(
                  label: 'Nombre o modelo',
                  hint: 'Ej. Seat León',
                  icon: Icons.directions_car_rounded,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Indica el nombre o modelo'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _variantController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: _decoration(
                  label: 'Motor o variante (opcional)',
                  hint: 'Ej. 1.5 TSI',
                  icon: Icons.settings_rounded,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<FuelType>(
                initialValue: _fuelType,
                dropdownColor: AppColors.surfaceElevated,
                decoration: _decoration(
                  label: 'Combustible',
                  icon: Icons.local_gas_station_rounded,
                ),
                items: FuelType.values
                    .map(
                      (fuel) => DropdownMenuItem(
                        value: fuel,
                        child: Text(fuel.fullName),
                      ),
                    )
                    .toList(),
                onChanged: (fuel) {
                  if (fuel != null) {
                    _fuelType = fuel;
                  }
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _consumptionController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: _decoration(
                  label: 'Consumo medio (L/100 km)',
                  hint: 'Ej. 6,1',
                  icon: Icons.speed_rounded,
                ),
                validator: (value) => _validateNumber(
                  value,
                  fieldName: 'consumo',
                  minimum: 0.1,
                  maximum: 100,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _capacityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                decoration: _decoration(
                  label: 'Capacidad del depósito (L)',
                  hint: 'Ej. 50',
                  icon: Icons.water_drop_rounded,
                ),
                validator: (value) => _validateNumber(
                  value,
                  fieldName: 'capacidad',
                  minimum: 1,
                  maximum: 500,
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text(
                    'Guardar coche',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  String? _validateNumber(
    String? rawValue, {
    required String fieldName,
    required double minimum,
    required double maximum,
  }) {
    final value = _parseNumber(rawValue);
    if (value == null) {
      return 'Indica un valor válido';
    }
    if (value < minimum || value > maximum) {
      return 'Introduce un $fieldName entre ${_formatNumber(minimum)} y '
          '${_formatNumber(maximum)}';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final variant = _variantController.text.trim();
    Navigator.of(context).pop(
      VehicleProfile(
        name: _nameController.text.trim(),
        variant: variant.isEmpty ? null : variant,
        fuelType: _fuelType,
        averageConsumption: _parseNumber(_consumptionController.text)!,
        tankCapacity: _parseNumber(_capacityController.text)!,
      ),
    );
  }

  static double? _parseNumber(String? value) =>
      double.tryParse(value?.trim().replaceAll(',', '.') ?? '');

  static String _formatNumber(double value) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return text.replaceAll('.', ',');
  }
}

class _FormIntro extends StatelessWidget {
  const _FormIntro();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 21),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Estos datos permiten calcular la autonomía teórica y preparan '
            'Surtio para estimar costes de repostaje.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
