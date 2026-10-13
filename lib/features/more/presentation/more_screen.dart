import 'package:flutter/material.dart';

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
              'Los precios y horarios proceden del servicio oficial de precios de carburantes del Gobierno de España. Son informativos y pueden variar: confirma el importe en la estación.\n\nLas distancias son en línea recta, no por carretera. Al elegir un municipio se calculan desde un punto de referencia de la zona.\n\nLos periodos largos del histórico se muestrean y pueden omitir variaciones breves.\n\nMapas: OpenFreeMap y datos de OpenStreetMap. Puedes consultar las atribuciones del proveedor en el mapa.',
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

  static const privacyText =
      'Surtio · Información de privacidad\nActualizada el 13 de octubre de 2026\n\nContacto: support@jvrlabs.es\n\nUbicación\nLa app solicita ubicación mientras la utilizas para centrar el mapa y calcular distancias. También puedes elegir una zona sin conceder ese permiso. Surtio no guarda un historial de ubicaciones ni solicita ubicación en segundo plano.\n\nDatos en tu dispositivo\nEl perfil de tu coche, los identificadores de estaciones favoritas, la zona elegida manualmente y el radio de búsqueda se guardan localmente. La posición del dispositivo no se guarda. No hay cuentas de usuario ni un servidor propio que reciba estos datos. El sistema operativo puede incluir las preferencias locales en sus copias de seguridad. Puedes borrar los datos desde los ajustes de Android o desinstalar la app.\n\nConexiones a servicios externos\nLa app consulta precios al servicio oficial de carburantes y carga mapas de OpenFreeMap. Las peticiones de red exponen tu dirección IP a sus proveedores; las teselas solicitadas corresponden a la zona visible del mapa. Consulta las políticas de estos servicios para conocer su tratamiento.\n\nNavegación y compartir\nAl abrir una ruta se envían las coordenadas de la estación a Google Maps o al navegador. Al compartir, la aplicación que elijas recibe el texto de la estación y el precio consultado. No se comparte tu perfil del coche.\n\nEsta versión no integra publicidad ni analítica de uso.';
}
