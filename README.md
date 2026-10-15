# Crisis Map

Aplicación Flutter para seguir **desastres naturales en un mapa** y coordinar la ayuda
ciudadana: los vecinos reportan incidencias con fotos, la app **avisa cuando te acercas
a una zona afectada** y reúne en un sitio los puntos de ayuda, los teléfonos de
emergencia y las donaciones.

## Funcionalidades

- **Mapa (OpenStreetMap)** con tu ubicación, las zonas afectadas y los puntos de ayuda.
- **Reportar incidencias** en dos pasos (datos + zona en el mapa):
  - Calle cortada → tramo (inicio y fin).
  - Terremoto e incendio → círculo (centro y radio ajustable).
  - Inundación → polígono de 3 o más puntos.
  - Gravedad (baja / media / alta) y hasta 4 fotos.
- **Alertas de cercanía**: aviso emergente y vibración cuando una incidencia activa entra
  en tu radio (500 m – 10 km, configurable con el icono de la campana). También avisa si
  estás *dentro* de la zona. No se avisa de tus propios reportes ni de los resueltos.
- **Ficha de incidencia**: distancia a ti, fotos (cualquiera puede añadir más),
  consejos de seguridad y, para el autor, marcar como resuelta o eliminar.
- **Lista de incidencias** ordenada por cercanía, con filtros por tipo.
- **Ayuda**: botón de llamada al 112, teléfonos útiles, puntos de ayuda cercanos
  (albergues, agua y comida, sanitarios, recogida de donaciones, puntos de encuentro)
  con "Cómo llegar", y consejos de qué hacer en cada situación + mochila de emergencia.
- **Donaciones**: enlaces a las webs oficiales de organizaciones (la app no gestiona
  pagos) y un **tablón solidario** donde los vecinos publican lo que ofrecen o necesitan.
- **Modo demo**: botón en el login para probarlo todo sin cuenta, con datos de ejemplo
  en el centro de Madrid. Mantén pulsado el mapa → "Simular que estoy aquí" para probar
  las alertas.

## Puesta en marcha

Requisitos: Flutter estable reciente (probado con Flutter 3.47 / Dart 3.13).

```bash
flutter pub get
flutter run            # en un móvil o emulador
flutter run -d chrome  # versión web
```

> **Windows**: si `flutter pub get` muestra *"Building with plugins requires symlink
> support"*, activa el **Modo de desarrollador** de Windows (`start ms-settings:developers`).
> Es necesario para compilar la versión de escritorio/Android desde Windows.

### Firebase

La app usa el proyecto `natural-crisis-map-7eea4` (configurado en
`lib/firebase_options.dart`) con:

- **Authentication** → proveedor *Correo electrónico/contraseña* activado.
- **Cloud Firestore** → publicar las reglas de [`firestore.rules`](firestore.rules):

  ```bash
  firebase deploy --only firestore:rules
  ```

  o copiarlas en *Consola de Firebase → Firestore Database → Reglas*. Si la base de datos
  se creó en "modo de prueba", esas reglas temporales caducan a los 30 días y la app
  mostrará "Firestore ha denegado el acceso".

Las fotos se guardan comprimidas (JPEG, máx. 1280 px) en base64 dentro de Firestore,
así que **no hace falta Firebase Storage ni el plan de pago**.

Estructura de datos:

| Colección | Contenido |
|---|---|
| `incidencias/{id}` | tipo, título, descripción, gravedad, fecha, autor, activa y geometría |
| `incidencias/{id}/fotos/{id}` | foto en base64 |
| `ayudas/{id}` | puntos de ayuda |
| `donaciones/{id}` | tablón solidario |

## Tests

```bash
flutter test
```

Cubren el cálculo de distancias a cada tipo de zona, la lógica de alertas, la
serialización de los modelos, el repositorio demo y un recorrido por la app en modo demo.

## Estructura

```
lib/
  main.dart                 # Arranque, tema y AuthGate (login ↔ app)
  models/                   # Incidencia, FotoIncidencia, PuntoAyuda, Donacion
  services/
    sesion.dart             # Usuario actual, modo demo y repositorio activo
    crisis_repository.dart  # Interfaz de datos
    firestore_repository.dart / demo_repository.dart
    ubicacion_service.dart  # GPS (y ubicación simulada en demo)
    alertas_service.dart    # Cálculo de incidencias cercanas y avisos
  screens/                  # Login, registro, home (pestañas), formularios
  widgets/                  # Mapa base, fichas de detalle, fotos, ajustes de alertas
  utils/                    # Geometría (distancias) y formato
```

## Limitaciones conocidas

- Las alertas funcionan con la app abierta (no hay seguimiento en segundo plano ni
  notificaciones push).
- Usa los servidores públicos de teselas de OpenStreetMap, pensados para uso ligero;
  para publicar la app a gran escala conviene un proveedor de mapas propio.
