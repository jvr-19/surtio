# Preparación de Surtio para Android

Estado a 16/10/2026: beta en desarrollo; todavía no hay versión publicada en Google Play.

## Comportamiento disponible

Mapa, precios oficiales, filtros de combustible, búsqueda por nombre o dirección, radio configurable en la lista, municipio manual, favoritos persistentes, histórico cuando hay datos, navegación externa, compartir y perfil local de vehículo.

## Validación local

- Flutter 3.41.7, Dart 3.11.5; Android SDK 36.
- Formato correcto, análisis sin incidencias y 44 pruebas Flutter correctas y tres pruebas del control de manifiesto.
- Recorrido en emulador Android API 36 con datos reales: lista, detalle, favoritos, privacidad y municipio manual.
- Pruebas de navegación externa a nivel de URI y contenido; pendiente verificación completa en teléfono físico.
- Bibliotecas nativas de 64 bits inspeccionadas con alineación ELF de al menos 16 KB; pendiente dispositivo con páginas de 16 KB.

## Antes de distribuir

1. Publicar y verificar la URL HTTPS de privacidad.
2. Completar ficha, audiencia, clasificación y Seguridad de los datos según app y proveedores reales.
3. AAB y APK 1.0.0+6 generados localmente con firma y sumas SHA-256 verificadas; validar su instalación mediante Google Play antes de distribuir.
4. Configurar el canal de prueba y recoger comentarios reales.
5. Cumplir los requisitos de acceso a producción que indique Play Console.

## Firma privada

La versión release exige una clave de subida local. Configura `android/key.properties` a partir del ejemplo. Mantén el archivo, la clave y sus copias de seguridad fuera del repositorio. `scripts/build-play-bundle.sh` comprueba la firma del AAB.

## Fuentes oficiales

- https://support.google.com/googleplay/android-developer/answer/14151465
- https://developer.android.com/google/play/requirements/target-sdk
- https://developer.android.com/guide/practices/page-sizes

## Revisión 1.0.0+6

Ubicación bajo acción expresa, exclusiones de copias/transferencias Android, tráfico HTTP bloqueado, privacidad ampliada y controles de manifiesto en CI. Ver [compliance-review.md](compliance-review.md). La evaluación de proveedores, identificación legal aplicable y declaraciones de Play siguen pendientes antes de publicar.
