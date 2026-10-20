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

## Seguridad de los datos pendiente — revisión del 20/10/2026

El formulario sigue como borrador incompleto y no se ha enviado como declaración definitiva. Se ha recibido respuesta del proveedor; la correspondencia y sus cabeceras no se publican en el repositorio.

En el borrador de Play se han completado las preguntas de ubicación aproximada y precisa: recogida y compartición para funcionalidad, opcional y sin afirmar procesamiento exclusivamente temporal. Es una preparación del formulario, no una aprobación de Google. La zona elegida manualmente no equivale por sí sola a ubicación física del usuario; el mapa también permite centrarse en la posición del dispositivo y generar solicitudes relacionadas con ella. Esta distinción debe conservarse al revisar el resultado final.

La categoría «IDs de dispositivo o de otro tipo» está seleccionada para revisión de la IP, pero sus preguntas siguen sin completar. No se han guardado declaraciones definitivas sobre su obligatoriedad, fines o compartición. Que una petición incluya una IP no basta para asignarle automáticamente un tipo de datos: Google exige valorar sus usos concretos.

La política pública de OpenFreeMap contempla registros de errores con IP/URL durante siete días y registros temporales de IP por incidentes de seguridad durante un máximo de treinta días. No se afirma que todos los tratamientos sean efímeros ni que toda conservación termine a los siete días. El papel de Cloudflare como encargado de OpenFreeMap no determina por sí solo la relación de OpenFreeMap con el desarrollador de una app integrada.

Falta concretar los usos reales de la IP, la posibilidad de excluir su tratamiento y la relación entre el desarrollador y el proveedor para evaluar las excepciones de compartición. Hay una segunda consulta preparada, sin enviar a fecha de esta revisión. La autorización del titular no sustituye la evidencia técnica necesaria para cerrar la declaración.

Fuentes públicas revisadas:
- https://support.google.com/googleplay/android-developer/answer/10787469
- https://openfreemap.org/privacy/
- https://www.cloudflare.com/cloudflare-customer-dpa/
- https://openfreemap.org/tos/

Las condiciones de OpenFreeMap del 14/10/2026 distinguen la edad del integrador (18 o más) de la de los usuarios finales de mapas integrados (cualquier edad). Por ello, la indicación general sobre menores de su política de privacidad no debe interpretarse por sí sola como una prohibición de mostrar el mapa a usuarios de 16–17 años.

## Prueba cerrada y publicación

En la comprobación del panel constan **0 testers que hayan aceptado participar**. No hay una versión de producción publicada. Guardar la ficha y las declaraciones no inicia los 14 días: hay que configurar y publicar la prueba cerrada, distribuir su enlace y reunir al menos 12 testers inscritos durante 14 días consecutivos.

Google describe el requisito en términos de testers e inscripción continua; no publica en esa guía una obligación expresa de 12 dispositivos físicos distintos. Recomienda diversidad de usuarios y dispositivos y valora participación real. No se garantiza que múltiples cuentas gestionadas por una sola persona sirvan para obtener producción.

Fuente: https://support.google.com/googleplay/android-developer/answer/14151465

## Preparación posterior

El 18/10/2026 se guardó la versión 1.0.0 (6), con su AAB y notas en español, como borrador de prueba interna. No se ha distribuido ni inicia el requisito de prueba cerrada. Se envió una consulta al contacto de privacidad de OpenFreeMap para aclarar inferencia de ubicación, tratamiento y conservación de datos, finalidades y opciones de exclusión/borrado; respuesta recibida el 19/10/2026; revisión adicional documentada arriba.
