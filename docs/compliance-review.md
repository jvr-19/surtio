# Revisión de privacidad, seguridad y publicación

Fecha: 16/10/2026. Versión revisada: 1.0.0+6. Este registro describe evidencias y tareas pendientes; no constituye una certificación jurídica ni una aprobación de Google Play.

## Alcance y titular

Proyecto publicado como particular bajo el nombre JVR Labs, según indicación del titular. La identificación legal completa del responsable queda pendiente de revisión y autorización de sus datos públicos antes del lanzamiento. Comparador informativo gratuito de precios de carburantes en España; sin cuentas, pagos, anuncios, analítica ni contenido aportado por usuarios. Revisar este alcance antes de añadir monetización o nuevas funciones. Ser particular no excluye automáticamente obligaciones de protección de datos o la consideración de actividad económica.

## Medidas incorporadas

| Área | Evidencia en la versión | Límite o seguimiento |
| --- | --- | --- |
| Minimización | Inicio sin solicitar ni consultar ubicación; acceso solo al pulsar el control de ubicación. Municipio manual disponible. | La ubicación aproximada de Android debe probarse manualmente. |
| Privacidad local | Posición GPS no persistida; preferencias y precios en almacenamiento privado. Copias Android y transferencia excluidas mediante reglas explícitas. | Verificar en distintos fabricantes; no garantiza seguridad frente a dispositivos comprometidos. |
| Transparencia | Política en la app y HTML equivalente: finalidad, contacto, proveedores, conservación, derechos, AEPD y revocación. | Publicar el HTML mediante HTTPS y verificarlo antes de la ficha de Play. |
| Proveedores | Precios/histórico: servicio oficial. Mapa: OpenFreeMap; posible CDN Cloudflare. Solicitudes del mapa revelan zona visible e IP. | No declarar «ningún dato recopilado» sin resolver Seguridad de los datos. No se presume tratamiento exclusivamente europeo. |
| Eliminación | Más > Gestionar datos y permisos abre los ajustes de la app; borrado completo desde almacenamiento Android. | Sin cuentas, no aplica un flujo de eliminación de cuentas de Surtio. El correo de soporte requiere gestión humana. |
| Seguridad | HTTPS en los servicios configurados; tráfico HTTP deshabilitado; componentes internos no exportados; claves fuera de Git. Logs de estaciones cercanas eliminados. | La revisión no es un pentest ni acredita ausencia de vulnerabilidades en dependencias. |
| Android/Play | Comprobación automatizada de permisos, configuración de backup y manifiesto release con API objetivo >=36. | El manifiesto final y las firmas deben revisarse en cada entrega. scripts/check_android_artifact.py verifica segmentos ELF de 64 bits; falta prueba de ejecución con páginas de 16 KB. Validación Play pendiente. |
| Accesibilidad | Alternativa en lista al mapa, etiquetas de controles, pantallas con texto al 200 % y teclado probadas. Atribución cartográfica situada fuera de la tarjeta inferior. | Revisión hablada con TalkBack, contraste completo y dispositivos físicos pendientes. No se declara conformidad WCAG/EN 301 549. |
| Datos y licencias | Licencia MIT del código; licencias Flutter accesibles en Más; atribución OpenStreetMap y enlace ODbL; fuente oficial y aviso de independencia. | Comprobar condiciones concretas de reutilización y avisos de dependencias nativas antes de publicar; no confundir MIT con la licencia de los datos. |

## Inventario de flujos

- **Ubicación:** Android/servicio de localización del dispositivo → memoria de Surtio para distancia y centrado. No se añade la posición GPS al endpoint nacional de precios. El mapa centrado produce peticiones relacionadas con esa zona.
- **Preferencias:** perfil del coche, favoritos, radio y municipio manual → almacenamiento local. Se conservan hasta edición/borrado/desinstalación.
- **Precios:** servicio oficial → copia local. La copia no se utiliza como alternativa después de 24 horas; puede permanecer en disco hasta reemplazo o borrado. No se afirma que se elimine automáticamente a las 24 horas.
- **Mapa:** OpenFreeMap/posible CDN → recursos y caché local. Su política contempla registros de errores con IP/URL y registros temporales de seguridad. Revisada el 16/10/2026; puede cambiar.
- **Compartir/ruta:** acción explícita del usuario → aplicación elegida; información de la estación y fecha de consulta, sin perfil del coche.
- **Soporte:** el usuario decide enviar correo a support@jvrlabs.es. El titular gestiona acceso, conservación y ejercicio de derechos; no enviar documentos de identidad sin necesidad.

## Permisos del manifiesto combinado

- INTERNET: fuente de precios, histórico y recursos de mapa.
- ACCESS_COARSE_LOCATION y ACCESS_FINE_LOCATION: ubicación opcional al pulsar su control; Android permite elegir aproximada. No hay permiso de ubicación en segundo plano.
- ACCESS_NETWORK_STATE y ACCESS_WIFI_STATE: incorporados por dependencias para consultar conectividad. No se utiliza la lista de redes Wi-Fi como función de Surtio.
- Permiso interno DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION con protección de firma: infraestructura AndroidX; no es un permiso solicitado al usuario.

No hay permisos de contactos, cámara, micrófono, identificador publicitario, SMS ni almacenamiento compartido amplio en la versión combinada revisada. La actividad de inicio es pública para el lanzador; proveedores de compartir, receptores y servicios propios no se exportan. AndroidX añade ProfileInstallReceiver exportado y protegido con android.permission.DUMP; el control solo admite ese receptor con esa protección explícita. El script de manifiesto rechaza nuevos permisos fuera de esta lista y componentes exportados adicionales hasta revisión.

## Seguridad de los datos de Google Play: preparación, no declaración enviada

El procesamiento exclusivamente local no se declara como recopilación en el formulario. La transmisión desde SDK también debe evaluarse. Las peticiones de teselas pueden revelar ubicación aproximada y, según zoom y zona, permitir una inferencia más detallada: no concluir «sin ubicación compartida» por no enviar un campo llamado GPS. La política del proveedor contempla retención en ciertos registros; no asumir procesamiento efímero para todos los casos. Revisar categorías, finalidades, obligatoriedad y excepciones de proveedor/acción iniciada por el usuario según el formulario real. Revisar también IP y datos técnicos. Mantener consistencia con el texto de privacidad y la versión distribuida.

No se ha completado ni enviado el formulario en esta revisión. Tampoco se han cambiado la audiencia, la clasificación de contenido ni declaraciones legales de la cuenta.

## Evaluación de normas y aplicabilidad

- **RGPD y LOPDGDD:** transparencia, minimización, seguridad, ejercicio de derechos y responsabilidad proactiva. La política no sustituye la gestión real del correo ni la evaluación de terceros. Documentar las relaciones y garantías aplicables antes de afirmar cumplimiento completo. No publicar DNI/NIF/domicilio del titular en el repositorio por defecto.
- **LSSI:** revisar el artículo 10 y el alcance de servicio de la sociedad de la información según la actividad real. El carácter gratuito o particular no resuelve por sí solo su aplicabilidad. Identificación y datos públicos adicionales pendientes de esa evaluación; no inventar domicilio ni datos fiscales.
- **Accesibilidad:** Ley 11/2023 y RD 193/2023 requieren analizar servicio y ámbito. Un comparador sin contratación no debe calificarse automáticamente como comercio electrónico; tampoco se presume una exención general. Se aplican mejoras de accesibilidad aunque no se haya certificado conformidad.
- **Google Play:** política de datos de usuario, permisos, API objetivo, compatibilidad de páginas de 16 KB, clasificación, ficha veraz y pruebas cerradas. El alta personal y los 12 testers/14 días siguen siendo asuntos de la cuenta/canal, no se sustituyen con pruebas automatizadas.
- **Propiedad intelectual/reutilización:** mantener licencias del código y de datos cartográficos, citar la fuente pública, no insinuar respaldo institucional. Revisar condiciones específicas del conjunto oficial y componentes nativos.
- **Funciones ausentes:** no hay ventas, anuncios, cuentas, cookies de analítica propias ni IA en Surtio. No añadir banners, consentimientos o declaraciones sobre estas funciones como si existieran. Reabrir la evaluación si cambian.

## Bloqueos y revisión humana antes de Google Play

1. URL de privacidad desplegada, pública, sin login y coherente con la app.
2. Seguridad de los datos y proveedores revisados y declarados; resolver transferencias/condiciones de uso cuando corresponda.
3. Identificación legal y condición económica del titular evaluadas para la ficha/aviso; publicar datos personales adicionales solo tras revisión del titular.
4. Revisión de audiencia y condiciones vigentes del proveedor cartográfico; su política menciona un público mayor de edad. No seleccionar audiencia infantil sin resolverlo.
5. Reutilización oficial y avisos de licencias nativas verificados.
6. TalkBack, navegación/compartir externos, permiso aproximado, borrado de almacenamiento y páginas de 16 KB verificados manualmente donde proceda.
7. Ficha, clasificación, verificación de cuenta, informe previo al lanzamiento y prueba cerrada completados. Solicitud de producción revisada por Google.

## Fuentes primarias consultadas

- RGPD: https://eur-lex.europa.eu/eli/reg/2016/679/oj/spa
- LOPDGDD: https://www.boe.es/buscar/act.php?id=BOE-A-2018-16673
- AEPD, transparencia en apps: https://www.aepd.es/guias/nota-tecnica-apps-moviles.pdf
- LSSI: https://www.boe.es/buscar/act.php?id=BOE-A-2002-13758
- Ley 11/2023: https://www.boe.es/buscar/act.php?id=BOE-A-2023-11022
- RD 193/2023: https://www.boe.es/buscar/act.php?id=BOE-A-2023-7417
- Google, datos de usuario: https://support.google.com/googleplay/android-developer/answer/10144311
- Google, Seguridad de los datos: https://support.google.com/googleplay/android-developer/answer/10787469
- Android, API objetivo: https://developer.android.com/google/play/requirements/target-sdk
- Android, páginas de 16 KB: https://developer.android.com/guide/practices/page-sizes
- Android, copias de seguridad: https://developer.android.com/identity/data/autobackup
- Android, tráfico sin cifrar: https://developer.android.com/privacy-and-security/risks/cleartext-communications
- OpenFreeMap: https://openfreemap.org/privacy/
- OpenStreetMap: https://www.openstreetmap.org/copyright

- AndroidX, receptor de perfiles protegido: https://developer.android.com/reference/androidx/profileinstaller/ProfileInstallReceiver

## Resultado de verificación local

44 pruebas Flutter, tres pruebas del verificador de manifiesto y tres recorridos completos en emulador API 36 pasan. Formato y análisis correctos. AAB/APK 1.0.0+6 firmados y comprobados; manifiesto combinado con API objetivo 36, controles de permisos y exclusiones correctos. Segmentos ELF de 64 bits alineados para 16 KB; alineación ZIP del APK verificada con zipalign -P 16. Sumas SHA-256 comprobadas. Esto no equivale a una prueba de ejecución en un dispositivo de 16 KB ni a una aprobación de Play. La identificación legal completa sigue pendiente de autorización de sus datos públicos; no se incorpora a estos textos nuevos.
