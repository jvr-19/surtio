# Verificación de primer inicio y recuperación

Fecha: 18/10/2026. Evidencias técnicas; no equivalen a una certificación de accesibilidad ni a la aprobación de Google Play.

## Pruebas automatizadas

- Bienvenida sin solicitar ubicación al entrar.
- Elección manual de municipio y cancelación con Atrás.
- Entrada sin elegir zona con aviso del punto inicial; bienvenida completada guardada para la siguiente apertura.
- Errores simulados de permiso denegado, servicio de ubicación desactivado y tiempo de espera: la alternativa manual continúa disponible.
- Posición aproximada simulada: permite continuar y no persiste coordenadas del dispositivo.
- Texto al 200 % y pantalla pequeña en los recorridos de error y selección manual.
- Recuperación de precios, rechazo de datos caducados y conservación de fecha original cubiertos por las pruebas de servicios.

El test `integration_test/offline_storage_test.dart` añade almacenamiento real del emulador Android: guarda una respuesta de prueba, vacía la caché en memoria, simula una pérdida de conexión y comprueba la recuperación desde disco y el rechazo a las 25 horas. No desconecta físicamente las interfaces de red ni reinicia el proceso.

El recorrido `integration_test/beta_smoke_test.dart` incorpora la bienvenida y conserva las pruebas con fuente oficial, favoritos, privacidad, mapa al 200 % y selección de marcadores.

## Resultado del 18/10/2026

55 pruebas Flutter correctas, análisis sin incidencias, tres recorridos de integración con la bienvenida y datos reales correctos en emulador Android API 36, y prueba adicional de caché en disco con conexión simulada como caída correcta. Captura de bienvenida en `docs/screenshots/00-welcome.png`.

## Revisión manual pendiente

- Conceder ubicación aproximada desde el diálogo real de Android, denegarla y revocarla desde Ajustes. Los escenarios simulados no sustituyen ese diálogo.
- Revisar verbalmente etiquetas, orden de foco y mensajes con TalkBack.
- Abrir una ruta y compartir con aplicaciones externas instaladas, incluida la cancelación y vuelta a Surtio.
- Borrar todos los datos desde Ajustes de Android y comprobar que desaparecen favoritos, perfil, zona, caché y estado de bienvenida.
- Ejecutar en un dispositivo con páginas de memoria de 16 KB; los controles de alineación de archivos no sustituyen esa ejecución.
- Probar en un teléfono físico cuando esté disponible.

Para los recorridos con datos reales, usar zonas elegidas para las pruebas; no guardar capturas de ubicaciones privadas o datos personales en el repositorio público.
