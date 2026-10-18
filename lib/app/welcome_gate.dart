import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_colors.dart';
import '../core/location/area_picker.dart';
import '../core/location/search_area.dart';
import '../features/map/data/services/fuel_station_api.dart';

class WelcomeGate extends StatefulWidget {
  const WelcomeGate({
    super.key,
    required this.child,
    this.area,
    this.api = const FuelStationApi(),
  });
  static const storageKey = 'welcome_completed_v1';
  final Widget child;
  final SearchAreaController? area;
  final FuelStationApi api;

  @override
  State<WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends State<WelcomeGate> {
  late final _area = widget.area ?? SearchAreaController.instance;
  bool _loading = true;
  bool _completed = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    var completed = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      completed = prefs.getBool(WelcomeGate.storageKey) ?? false;
    } catch (_) {
      // Preferences must not prevent entry into the app.
    }
    await _area.initialize();
    if (mounted) {
      setState(() {
        _completed = completed;
        _loading = false;
      });
    }
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    await _area.pendingPersistence;
    var saved = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      saved = await prefs.setBool(WelcomeGate.storageKey, true);
    } catch (_) {
      // Continue for this session even when storage is unavailable.
    }
    if (!mounted) return;
    setState(() {
      _completed = true;
      _busy = false;
    });
    if (!saved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo guardar la bienvenida. Puede aparecer al volver a abrir Surtio.',
              ),
            ),
          );
        }
      });
    }
  }

  Future<void> _chooseArea() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final selected = await pickSearchArea(
      context,
      api: widget.api,
      controller: _area,
    );
    if (!mounted) return;
    if (selected) {
      await _finish();
    } else {
      setState(() => _busy = false);
    }
  }

  Future<void> _useLocation() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _area.useDeviceLocation();
      if (mounted) await _finish();
    } catch (error) {
      if (!mounted) return;
      final message = switch (error) {
        LocationServiceDisabledException() =>
          'La ubicación del dispositivo está desactivada. Puedes activarla en Android o elegir un municipio.',
        PermissionDeniedException() =>
          'No se ha concedido acceso a la ubicación. Puedes elegir un municipio sin dar permiso.',
        TimeoutException() =>
          'No hemos podido obtener tu ubicación a tiempo. Inténtalo de nuevo o elige un municipio.',
        _ =>
          'No se pudo obtener tu ubicación. Inténtalo de nuevo o elige un municipio.',
      };
      setState(() {
        _busy = false;
        _error = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_completed) return widget.child;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.local_gas_station_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Encuentra dónde repostar',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Compara precios de carburantes en España. Elige una zona para empezar; podrás cambiarla cuando quieras.',
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.backgroundDeep,
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _busy ? null : _chooseArea,
                    icon: const Icon(Icons.search),
                    label: const Text('Elegir municipio'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _busy ? null : _useLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Usar mi ubicación'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'La ubicación es opcional. Solo pediremos permiso si eliges usarla; también puedes permitir ubicación aproximada.',
                  ),
                  if (_busy)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Semantics(
                        liveRegion: true,
                        child: const Text('Un momento…'),
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Semantics(liveRegion: true, child: Text(_error!)),
                    ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _busy ? null : _finish,
                    child: const Text('Explorar sin elegir zona'),
                  ),
                  Text(
                    'En ese caso empezaremos en ${_area.area.label}. No se consultará tu ubicación.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
