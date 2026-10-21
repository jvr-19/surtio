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

## Beta 1.0.0+7 — 20/10/2026

AAB y APK arm64 generados y firmados, con certificados comparados con la versión anterior, paquete/código de versión comprobados, controles de manifiesto y alineación pasados y sumas SHA-256 registradas fuera de Git. Análisis sin incidencias, 55 pruebas Flutter y tres pruebas del control de manifiesto correctas.

Compilación 7 aceptada por Play, con SDK objetivo 36. El borrador interno sustituye la compilación 6 por la 7; su lista existente no se modifica. El canal cerrado Alpha tiene España, el grupo `surtio-beta-testers@googlegroups.com` y contacto `support@jvrlabs.es`; versión 1.0.0 (7) confirmada y guardada en Resumen de publicación. Play muestra «Ya se puede publicar» para esa versión. Esto no acredita todavía distribución ni aprobación de Google.

Las comprobaciones previas detectaron una declaración adicional de ID de publicidad incompleta: se guardó «No» conforme al manifiesto y a la implementación. Se confirmó el envío de catorce cambios a revisión. Play los agrupa como «Cambios en revisión», con las comprobaciones rápidas todavía en curso: el pase efectivo a revisión queda condicionado a que terminen correctamente. No se afirma aprobación ni disponibilidad de la beta. El grupo contiene un miembro; no equivale a un tester inscrito en Play. No hay doce participantes confirmados ni plazo de catorce días acreditado.

## Corrección de la ficha rechazada — 21/10/2026

Google rechazó el envío del día 20 por «Missing Source Link for Government Information», dentro de la política de afirmaciones engañosas. El área indicada fue la descripción completa en español: mencionaba la fuente oficial, pero no incluía su URL. El aviso de independencia ya existía.

Se guardó una descripción corregida con enlaces explícitos al Ministerio y al Geoportal, identificando el origen de los datos de estaciones, ubicación, precios actuales e históricos y horarios. El aviso de que Surtio no representa a ninguna entidad gubernamental ni tiene afiliación o respaldo del Gobierno se trasladó al principio. La app ya ofrece un enlace al Geoportal en Más. No se cambió el binario 1.0.0+7 por esta corrección de metadatos.

Se reenviaron los catorce cambios de la beta cerrada con la ficha corregida. El historial registra el envío 2 del 21/10/2026 a las 12:39 (Canarias) como «En revisión». Play mostró «Cambios en revisión», con comprobaciones rápidas todavía en curso. No constituye aprobación ni disponibilidad para testers.

Referencias verificadas:
- https://support.google.com/googleplay/android-developer/answer/9514050
- https://www.miteco.gob.es/es/energia/servicios/consultas-de-carburantes.html
- https://geoportalgasolineras.es/
