import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/map/data/models/fuel_station.dart';

abstract final class StationActions {
  static Uri routeUri(FuelStation station) =>
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '${station.latitude},${station.longitude}',
        'travelmode': 'driving',
      });

  static String shareText(FuelStation station, FuelType fuel) {
    final price = station.priceFor(fuel);
    final priceText = price == null
        ? ''
        : '\n${fuel.fullName}: ${price.toStringAsFixed(3).replaceAll('.', ',')} €/L';
    final map = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${station.latitude},${station.longitude}',
    });
    return '${station.name}\n${station.address}, ${station.municipality}$priceText\nPrecio consultado en Surtio; puede cambiar.\n$map';
  }

  static Future<void> openUrl(BuildContext context, Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Show the same recoverable message for unsupported links and failures.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir el enlace. Comprueba que tienes una aplicación compatible.',
          ),
        ),
      );
    }
  }

  static Future<void> navigate(BuildContext context, FuelStation station) =>
      openUrl(context, routeUri(station));

  static Future<void> share(
    BuildContext context,
    FuelStation station,
    FuelType fuel,
  ) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          text: shareText(station, fuel),
          subject: 'Gasolinera en Surtio',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el menú para compartir.'),
          ),
        );
      }
    }
  }
}
