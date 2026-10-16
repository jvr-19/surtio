# Seguridad de Surtio

Surtio está en fase beta. Las correcciones se aplican a la versión actual de la rama principal; no se ofrece soporte de seguridad para APK antiguos ni un plazo de respuesta garantizado.

Para comunicar una vulnerabilidad, escribe a **support@jvrlabs.es**. Incluye versión, dispositivo, pasos para reproducir y el impacto observado. Evita publicar vulnerabilidades sin resolver en una incidencia pública y no envíes contraseñas, claves de firma, documentos de identidad ni datos de otras personas. Usa datos ficticios en las reproducciones.

Antes de distribuir una versión se revisan las pruebas, el manifiesto Android, las firmas y los archivos que se subirán a Git. Los controles automáticos no sustituyen una auditoría independiente. Consulta [la revisión de cumplimiento](docs/compliance-review.md) para ver el alcance y los asuntos pendientes.

Las credenciales y claves de subida se mantienen fuera del repositorio. Si se expone un secreto, hay que revocarlo o sustituirlo; borrarlo en un commit posterior no basta.
