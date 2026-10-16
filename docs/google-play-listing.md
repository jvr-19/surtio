# Ficha de Google Play · Surtio

## Nombre
Surtio: precios de gasolina

## Descripción breve
Compara precios de carburantes, guarda estaciones y encuentra dónde repostar.

## Descripción completa
Encuentra dónde repostar comparando los precios oficiales de gasolineras en España.

Con Surtio puedes:
- Consultar estaciones en el mapa o en una lista.
- Comparar gasolina 95, gasolina 98, diésel, diésel premium y GLP.
- Ordenar estaciones por precio o distancia.
- Buscar una zona sin conceder acceso a tu ubicación.
- Guardar tus gasolineras favoritas.
- Consultar la evolución del precio por estación y combustible.
- Abrir una ruta y compartir una estación.
- Guardar el perfil de tu coche en tu dispositivo.

Los precios y horarios proceden de la fuente oficial de carburantes del Gobierno de España. Los precios son informativos y pueden cambiar: confirma el importe antes de repostar. Las distancias son en línea recta. Los periodos largos del histórico utilizan muestras y pueden omitir cambios breves.

Surtio es una aplicación independiente, sin afiliación ni respaldo del Gobierno ni de las estaciones mostradas. No requiere crear una cuenta.

## Contacto
support@jvrlabs.es

## Material pendiente antes de publicar
- URL pública de privacidad pendiente de despliegue: archivo preparado también en la web JVR Labs, public/surtio/privacy.html. Ruta prevista /surtio/privacy.html. Verificar que devuelve HTTP 200 en producción antes de indicarla en Google Play.
- Material preparado: docs/screenshots/ (capturas Android reales), docs/store-assets/app-icon.png (512 × 512) y docs/store-assets/feature-graphic.png (1024 × 500), con fuentes SVG. Seleccionar las capturas finales antes de publicar.
- Categoría sugerida: Mapas y navegación.
- Completar clasificación de contenido y audiencia según el cuestionario real.
- Completar Seguridad de los datos después de revisar el comportamiento de OpenFreeMap y sus subproveedores: la zona visible puede revelarse por las peticiones de teselas. No inferir “no recopila datos” solo porque Surtio no tiene servidor propio.
- Confirmar si la cuenta dispone de producción o exige prueba cerrada desde Play Console.
