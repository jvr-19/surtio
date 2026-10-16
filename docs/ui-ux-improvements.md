# Mejoras de producto — 13/10/2026

## Implementado

- Búsqueda local por nombre o dirección sobre estaciones con precio del combustible seleccionado.
- Radio configurable de 5, 10, 20 y 50 km en Cerca. El mapa comparte el radio elegido y ajusta el zoom.
- Mensajes específicos para búsquedas sin coincidencias y zonas sin estaciones.
- Navegación Material con estados seleccionados y accesibilidad estándar.
- Controles de combustible de 48 puntos de altura.
- Tipografía del sistema: retirada una familia no incluida entre los recursos.
- README con captura, instalación, límites de datos y arquitectura; guía de contribución, plantillas de incidencias y pull requests.
- Flujo de GitHub Actions para formato, análisis y pruebas con Flutter 3.41.7.
- Archivos .DS_Store retirados del índice de Git sin borrar los archivos locales.

## Verificación

30 pruebas pasan. Análisis sin incidencias y formato correcto. Prueba de búsqueda/radio y prueba en pantalla de 360 × 800 con texto al 150 %. Recorrido Android en emulador API 36 con fuente oficial: lista, detalle, favoritos, privacidad y municipio manual. Capturas renovadas en docs/screenshots.

La primera ejecución de GitHub Actions detectó una carpeta vacía de recursos declarada en pubspec.yaml; se ha retirado la declaración y la carga de logotipos inexistentes. Las compilaciones firmadas anteriores en dist no incluyen estas mejoras; necesitan reconstruirse antes de distribuirlas.

## Próximas mejoras

- Revisar todas las pantallas con lector de pantalla, texto al 200 % y teclado abierto.
- Validar compartir y navegación externa en un teléfono físico.

Segunda tanda: radio compartido y persistente, zona manual persistente sin guardar posición del dispositivo, hora de consulta y botón de actualización en mapa. Privacidad actualizada. Versión 1.0.0+3.

Paquete AAB de esta tanda generado y firmado como 1.0.0+3 en la carpeta local dist, excluida de Git. Las instalaciones APK anteriores permanecen en 1.0.0+2.

## Mapa y accesibilidad — versión 1.0.0+4

- Colisiones de etiquetas activadas en el mapa y prioridad de colocación por precio ascendente. Las estaciones permanecen en la fuente y la lista completa; acercar el mapa permite ver más etiquetas.
- La fuente se vacía al no haber estaciones, evitando conservar marcadores de otra zona.
- Tarjeta de estación en el mapa con desplazamiento cuando el texto ocupa más espacio.
- Selectores de combustible con estado seleccionado y nombres completos para accesibilidad; botón de ubicación con descripción.
- Lista adaptada al teclado abierto; estadísticas del vehículo en columna con texto grande; precios, distancia, acciones y formulario con tamaños adaptables.
- Pruebas automáticas con texto al 200 %, pantalla de 360 × 800 y teclado simulado. La revisión con lector de pantalla real y teléfono físico sigue pendiente.

El AAB 1.0.0+3 anterior no incorpora esta tanda.

Validación de esta tanda: 32 pruebas correctas y análisis sin incidencias. Recorrido Android con datos reales y prueba adicional del mapa al 200 % completados en emulador API 36. Captura técnica en docs/screenshots/08-map-large-text.png.


## Selección y recuperación — versión 1.0.0+5

- Tocar una etiqueta del mapa selecciona la estación; el cambio de combustible conserva la selección si sigue disponible.
- Copia local de precios públicos con límite de 24 horas, fecha original visible y nuevos intentos de conexión. El fondo del mapa necesita Internet.
- Actualizar conserva el contenido visible; el detalle y el texto compartido incluyen la fecha de consulta.
- Precios no válidos excluidos y cambios rápidos de combustible protegidos frente a resultados antiguos.
- 41 pruebas automáticas correctas, incluyendo archivo local, recuperación de red y errores de compartir/navegación.
- Solo hay emulador disponible. La revisión hablada con TalkBack y las interfaces externas de navegación/compartir quedan pendientes de comprobación manual.

Validación del 16/10/2026: análisis sin incidencias, 41 pruebas automáticas y tres recorridos completos en emulador Android API 36 correctos: recorrido principal, mapa al 200 % y selección real de marcadores con cambio rápido de combustible.

AAB y APK arm64 de 1.0.0+5 generados en dist (fuera de Git), con firmas y sumas SHA-256 verificadas.
