# Surtio

Compara precios oficiales de combustible en España y encuentra dónde repostar. Una app Flutter con mapa, búsqueda por municipio, favoritos y perfil de vehículo.

> En desarrollo y preparación de beta. Todavía no está publicada en Google Play.

## La app

- Mapa y lista de gasolineras con selección compartida de combustible y zona.
- Búsqueda por estación o dirección y radios de 5, 10, 20 y 50 km en la lista.
- Ordenación por precio o distancia en línea recta.
- Radio compartido entre mapa y lista, con zona manual y radio recordados entre sesiones.
- Hora de consulta visible y actualización manual de precios.
- Detalle de estación, histórico cuando está disponible, navegación y compartir.
- Favoritos y perfil de vehículo guardados en el dispositivo.
- Selección manual de municipio sin conceder acceso a ubicación.

<p>
  <img src="docs/screenshots/01-nearby.png" width="240" alt="Lista de gasolineras y precios de Surtio" />
</p>

Captura del recorrido de prueba en Android con datos oficiales; los precios mostrados corresponden al momento de la consulta.

## Ejecutar en desarrollo

Necesitas Flutter con Dart compatible con `pubspec.yaml`, Android SDK y un dispositivo o emulador. La versión de Flutter utilizada se puede consultar en `.github/workflows/flutter.yml`.

```sh
flutter pub get
flutter run
```

La conexión a Internet permite actualizar los precios y cargar el mapa. Si falla la actualización, se pueden consultar los últimos precios guardados durante un máximo de 24 horas, indicando su fecha original. El fondo del mapa necesita conexión. Toca una etiqueta de precio para seleccionar su estación. La ubicación es opcional. Android es la plataforma de lanzamiento prioritaria; las demás plataformas no tienen validación equivalente.

## Comprobar cambios

```sh
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

La prueba de integración en `integration_test/beta_smoke_test.dart` requiere un dispositivo Android y conexión a los servicios oficiales.

## Datos y precisión

Los precios proceden del servicio público de carburantes del Ministerio competente en España. Pueden cambiar entre la consulta y el repostaje. Las distancias mostradas son en línea recta, no distancias por carretera. El histórico depende de la disponibilidad de la fuente; no se inventan precios cuando faltan datos.

## Estructura

- `lib/app`: navegación y tema visual.
- `lib/core`: ubicación, combustible, favoritos y acciones compartidas.
- `lib/features`: mapa, lista, detalle, vehículo y ajustes.
- `test`: pruebas de comportamiento.
- `docs`: privacidad, ficha de tienda y preparación de la beta.

## Contribuir y comunicar fallos

Consulta [CONTRIBUTING.md](CONTRIBUTING.md). Para incidencias privadas o dudas: support@jvrlabs.es. No publiques claves, contraseñas ni datos personales en las issues.

## Compilación para Google Play

Consulta [la preparación del lanzamiento](docs/launch-readiness.md) y `scripts/build-play-bundle.sh`. Las claves de firma y `android/key.properties` son privados y deben mantenerse fuera de Git. El repositorio no contiene una clave de firma pública de desarrollo para versiones de lanzamiento.

## Privacidad y preparación de publicación

La ubicación solo se solicita al pulsar su control; la búsqueda manual funciona sin permiso. La app incluye privacidad y acceso a ajustes para borrar datos o revocar permisos. Consulta [la revisión de cumplimiento](docs/compliance-review.md) para conocer las medidas verificadas y los asuntos todavía pendientes. No se declara certificación normativa ni aprobación de Google Play.
