import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/legal/privacy_policy.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/stations/station_actions.dart';
import '../../favorites/presentation/favorites_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Más')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Surtio',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Compara precios oficiales de combustible y encuentra dónde repostar.',
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Mis favoritos'),
            subtitle: const Text('Tus estaciones guardadas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacidad'),
            onTap: () => _showInfo(context, 'Privacidad', privacyText),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Fuentes y precisión'),
            onTap: () => _showInfo(
              context,
              'Fuentes y precisión',
              'Los precios y horarios proceden del servicio oficial de precios de carburantes del Gobierno de España. Surtio es una aplicación independiente, sin afiliación ni respaldo del Gobierno. Son informativos y pueden variar: confirma el importe en la estación.\n\nLas distancias son en línea recta, no por carretera. Al elegir un municipio se calculan desde un punto de referencia de la zona.\n\nLos periodos largos del histórico se muestrean y pueden omitir variaciones breves.\n\nMapas: OpenFreeMap y datos de OpenStreetMap. Puedes consultar las atribuciones del proveedor en el mapa.',
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Contactar con soporte'),
            subtitle: const Text('support@jvrlabs.es'),
            onTap: () => StationActions.openUrl(
              context,
              Uri(
                scheme: 'mailto',
                path: 'support@jvrlabs.es',
                query: 'subject=Surtio%20-%20Soporte',
              ),
            ),
          ),
        ),
        ListTile(
          title: const Text('Fuente oficial de precios'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => StationActions.openUrl(
            context,
            Uri.parse('https://geoportalgasolineras.es/'),
          ),
        ),
        ListTile(
          title: const Text('OpenFreeMap'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => StationActions.openUrl(
            context,
            Uri.parse('https://openfreemap.org/'),
          ),
        ),
        ListTile(
          title: const Text('© OpenStreetMap contributors'),
          subtitle: const Text('Datos del mapa · licencia ODbL'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => StationActions.openUrl(
            context,
            Uri.parse('https://www.openstreetmap.org/copyright'),
          ),
        ),
        ListTile(
          title: const Text('Privacidad de OpenFreeMap'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => StationActions.openUrl(
            context,
            Uri.parse('https://openfreemap.org/privacy/'),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Gestionar datos y permisos'),
          subtitle: const Text(
            'Abre los ajustes de Android para borrar datos o cambiar permisos',
          ),
          onTap: () => _openSettings(context),
        ),
        ListTile(
          title: const Text('Licencias de software'),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'Surtio',
            applicationLegalese: 'JVR Labs',
          ),
        ),
      ],
    ),
  );

  static Future<void> _openSettings(BuildContext context) async {
    try {
      if (await Geolocator.openAppSettings()) return;
    } catch (_) {
      // The OS settings screen may not be available on every platform.
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Abre Ajustes > Aplicaciones > Surtio para gestionar datos y permisos.',
        ),
      ),
    );
  }

  static void _showInfo(BuildContext context, String title, String text) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SelectableText(
                text,
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
            ),
          ),
        ),
      );

  static const privacyText = PrivacyPolicy.text;
}
