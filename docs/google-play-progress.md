# Estado de configuración en Google Play

Comprobado el 18/10/2026 en Play Console: **10 de 11 tareas de configuración de la aplicación completadas**. Completado significa guardado y preparado para revisión; no significa que Google lo haya aprobado ni que la aplicación esté publicada.

| Tarea | Estado guardado |
| --- | --- |
| Privacidad | https://www.jvrlabs.es/surtio/privacy.html, comprobada por HTTPS con HTTP 200 y contenido idéntico al texto revisado |
| Datos de inicio de sesión | Acceso sin restricciones; no hay cuenta, pago ni credenciales |
| Anuncios | La aplicación no contiene anuncios |
| Clasificación de contenido | IARC completado; PEGI 3 en Europa |
| Audiencia objetivo | 16–17 y a partir de 18 años, según indicación del titular |
| Seguridad de los datos | Borrador incompleto; no enviado como declaración definitiva |
| Aplicación gubernamental | No; Surtio es independiente de la Administración |
| Funciones financieras | No ofrece funciones financieras |
| Salud | No ofrece funciones de salud |
| Categoría y contacto | Mapas y navegación; support@jvrlabs.es; https://www.jvrlabs.es/ |
| Ficha de Play Store | Español de España, nombre y descripciones, icono, gráfico destacado y cuatro capturas reales; lista para enviar a revisión |

## Seguridad de los datos pendiente

El borrador recoge HTTPS, ausencia de cuentas y ubicación aproximada/precisa como categorías a revisar por la información que pueden revelar las peticiones de mapas. No se han fijado definitivamente la obligatoriedad, procesamiento temporal, finalidades o categorías adicionales relacionadas con IP/registros. Se necesita resolver estos aspectos con evidencia del proveedor antes de cerrar la declaración; una autorización del titular no sustituye esa evidencia.

OpenFreeMap declara posibles registros de errores con IP/URL y uso de Cloudflare. La clasificación de estos flujos para el formulario requiere confirmar su tratamiento concreto. No se declara «sin recopilación» por el simple hecho de no tener backend propio.

Fuentes:
- https://support.google.com/googleplay/android-developer/answer/10787469
- https://openfreemap.org/privacy/
- https://openfreemap.org/tos/

Las condiciones de OpenFreeMap del 14/10/2026 distinguen la edad del integrador (18 o más) de la de los usuarios finales de mapas integrados (cualquier edad). Por ello, la indicación general sobre menores de su política de privacidad no debe interpretarse por sí sola como una prohibición de mostrar el mapa a usuarios de 16–17 años.

## Prueba cerrada y publicación

En la comprobación del panel constan **0 testers que hayan aceptado participar**. No hay una versión de producción publicada. Guardar la ficha y las declaraciones no inicia los 14 días: hay que configurar y publicar la prueba cerrada, distribuir su enlace y reunir al menos 12 testers inscritos durante 14 días consecutivos.

Google describe el requisito en términos de testers e inscripción continua; no publica en esa guía una obligación expresa de 12 dispositivos físicos distintos. Recomienda diversidad de usuarios y dispositivos y valora participación real. No se garantiza que múltiples cuentas gestionadas por una sola persona sirvan para obtener producción.

Fuente: https://support.google.com/googleplay/android-developer/answer/14151465

## Preparación posterior

El 18/10/2026 se guardó la versión 1.0.0 (6), con su AAB y notas en español, como borrador de prueba interna. No se ha distribuido ni inicia el requisito de prueba cerrada. Se envió una consulta al contacto de privacidad de OpenFreeMap para aclarar inferencia de ubicación, tratamiento y conservación de datos, finalidades y opciones de exclusión/borrado; pendiente de respuesta.
