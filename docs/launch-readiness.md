# Preparación de Surtio para Android

Estado a 20/10/2026: beta 1.0.0+7 preparada; todavía no hay versión publicada en Google Play.

## Comportamiento disponible

Mapa, precios oficiales, filtros de combustible, búsqueda por nombre o dirección, radio configurable en la lista, municipio manual, favoritos persistentes, histórico cuando hay datos, navegación externa, compartir y perfil local de vehículo.

## Validación local

- Flutter 3.41.7, Dart 3.11.5; Android SDK 36.
- Formato correcto, análisis sin incidencias y 55 pruebas Flutter correctas y tres pruebas del control de manifiesto.
- Recorrido en emulador Android API 36 con datos reales: lista, detalle, favoritos, privacidad y municipio manual.
- Pruebas de navegación externa a nivel de URI y contenido; pendiente verificación completa en teléfono físico.
- Bibliotecas nativas de 64 bits inspeccionadas con alineación ELF de al menos 16 KB; pendiente dispositivo con páginas de 16 KB.

## Antes de distribuir

1. URL HTTPS de privacidad publicada y verificada.
2. Ficha, audiencia, clasificación, Seguridad de los datos e ID publicitario guardados; envío de la beta cerrada solicitado a Google.
3. AAB y APK 1.0.0+7 generados localmente con firma y sumas SHA-256 verificadas; validar su instalación mediante Google Play antes de distribuir.
4. Canal cerrado configurado con España y grupo de testers; esperar aprobación/disponibilidad y recoger comentarios reales.
5. Cumplir los requisitos de acceso a producción que indique Play Console.

## Firma privada

La versión release exige una clave de subida local. Configura `android/key.properties` a partir del ejemplo. Mantén el archivo, la clave y sus copias de seguridad fuera del repositorio. `scripts/build-play-bundle.sh` comprueba la firma del AAB.

## Fuentes oficiales

- https://support.google.com/googleplay/android-developer/answer/14151465
- https://developer.android.com/google/play/requirements/target-sdk
- https://developer.android.com/guide/practices/page-sizes

## Revisión 1.0.0+6

Ubicación bajo acción expresa, exclusiones de copias/transferencias Android, tráfico HTTP bloqueado, privacidad ampliada y controles de manifiesto en CI. Ver [compliance-review.md](compliance-review.md). La evaluación de proveedores, identificación legal aplicable y declaraciones de Play siguen pendientes antes de publicar.

## Compilación 1.0.0+7 — 20/10/2026

Incluye bienvenida con ubicación opcional, búsqueda y detalle simplificados, precios por carburante en Favoritos, selector de municipio desplazable y corrección de fechas del histórico durante los cambios de hora.

AAB y APK arm64 firmados con el mismo certificado de subida que la versión anterior. Comprobados paquete es.jvrlabs.surtio, código de versión 7, manifiesto release, alineación ELF de 64 bits y alineación ZIP de 16 KB del APK. Sumas SHA-256 registradas junto a los archivos locales, excluidos de Git. El control de alineación no sustituye una prueba de ejecución con páginas de 16 KB.

Seguridad de los datos está guardada en Play Console. El canal cerrado se ha configurado con España y el grupo Surtio Beta Testers; guardar esa configuración no inicia el plazo de participación. Consultar google-play-progress.md para el estado de las versiones y del envío a revisión.
