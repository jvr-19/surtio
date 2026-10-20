# Estado de configuración en Google Play

El 18/10/2026 se comprobaron diez de once tareas de configuración completadas. El 20/10/2026 se guardó también Seguridad de los datos en Resumen de publicación, pendiente de envío a revisión. Completado significa guardado y preparado para revisión; no significa que Google lo haya aprobado ni que la aplicación esté publicada.

| Tarea | Estado guardado |
| --- | --- |
| Privacidad | https://www.jvrlabs.es/surtio/privacy.html, comprobada por HTTPS con HTTP 200 y contenido idéntico al texto revisado |
| Datos de inicio de sesión | Acceso sin restricciones; no hay cuenta, pago ni credenciales |
| Anuncios | La aplicación no contiene anuncios |
| Clasificación de contenido | IARC completado; PEGI 3 en Europa |
| Audiencia objetivo | 16–17 y a partir de 18 años, según indicación del titular |
| Seguridad de los datos | Guardada el 20/10/2026 en Resumen de publicación; no enviada todavía a revisión |
| Aplicación gubernamental | No; Surtio es independiente de la Administración |
| Funciones financieras | No ofrece funciones financieras |
| Salud | No ofrece funciones de salud |
| Categoría y contacto | Mapas y navegación; support@jvrlabs.es; https://www.jvrlabs.es/ |
| Ficha de Play Store | Español de España, nombre y descripciones, icono, gráfico destacado y cuatro capturas reales; lista para enviar a revisión |

## Seguridad de los datos guardada — 20/10/2026

Play Console confirmó «Cambio guardado. Para enviarlo a revisión, ve a Resumen de publicación». No se ha pulsado el envío a revisión ni publicado una versión.

La declaración guardada incluye ubicación aproximada y precisa, recogida y compartición para funcionalidad, opcional y sin afirmar procesamiento exclusivamente temporal. La vista previa muestra cifrado en tránsito y la política de privacidad pública. No se declara una insignia de eliminación, auditoría independiente ni cumplimiento de familias.

Se retiró la categoría provisional «IDs de dispositivo o de otro tipo» tras revisar la guía de Android: recibir una IP en una conexión no equivale automáticamente a obtener un identificador de dispositivo, navegador o app a partir de ella. La búsqueda en código de Surtio y dependencias declaradas no encontró identificadores publicitarios, de instalación ni seguimiento; el adaptador Android de MapLibre GL 0.27.1 devuelve false para getTelemetryEnabled y no activa telemetría con setTelemetryEnabled. Esta conclusión debe reabrirse si cambia el SDK, se añaden identificadores o se acredita un uso distinto de los datos de red.

La IP sigue siendo un dato personal relevante para la política de privacidad. No se afirma que no se transmita ni que no pueda aparecer en registros. La política pública de OpenFreeMap contempla IP/URL en errores durante siete días y registros de IP en incidentes de seguridad durante hasta treinta días. No se afirma procesamiento exclusivamente efímero ni conservación universal de siete días. Los permisos opcionales y las solicitudes cartográficas relacionadas con el centrado en el dispositivo justifican mantener ubicación en la declaración; seleccionar un municipio manualmente no equivale por sí solo a comunicar la ubicación física del usuario.

No se aplicó una exención general de compartición basada solo en que Cloudflare sea encargado de OpenFreeMap. La respuesta del proveedor y sus cabeceras se mantienen fuera del repositorio público. La segunda consulta preparada no se ha enviado, según indicación del titular.

Fuentes públicas revisadas:
- https://support.google.com/googleplay/android-developer/answer/10787469
- https://developer.android.com/privacy-and-security/declare-data-use
- https://openfreemap.org/privacy/
- https://www.cloudflare.com/cloudflare-customer-dpa/
- https://openfreemap.org/tos/

Las condiciones de OpenFreeMap del 14/10/2026 distinguen la edad del integrador (18 o más) de los usuarios finales de mapas integrados (cualquier edad). La audiencia guardada se mantiene en 16–17 y mayores de 18 años.

## Prueba cerrada y publicación

En la comprobación del panel constan **0 testers que hayan aceptado participar**. No hay una versión de producción publicada. Guardar la ficha y las declaraciones no inicia los 14 días: hay que configurar y publicar la prueba cerrada, distribuir su enlace y reunir al menos 12 testers inscritos durante 14 días consecutivos.

Google describe el requisito en términos de testers e inscripción continua; no publica en esa guía una obligación expresa de 12 dispositivos físicos distintos. Recomienda diversidad de usuarios y dispositivos y valora participación real. No se garantiza que múltiples cuentas gestionadas por una sola persona sirvan para obtener producción.

Fuente: https://support.google.com/googleplay/android-developer/answer/14151465

## Preparación posterior

El 18/10/2026 se guardó la versión 1.0.0 (6), con su AAB y notas en español, como borrador de prueba interna. No se ha distribuido ni inicia el requisito de prueba cerrada. Se envió una consulta al contacto de privacidad de OpenFreeMap para aclarar inferencia de ubicación, tratamiento y conservación de datos, finalidades y opciones de exclusión/borrado; respuesta recibida el 19/10/2026; revisión adicional documentada arriba.
