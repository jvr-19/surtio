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
