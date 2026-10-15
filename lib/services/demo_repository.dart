import 'dart:async';

import 'package:latlong2/latlong.dart';

import '../models/donacion.dart';
import '../models/foto_incidencia.dart';
import '../models/incidencia.dart';
import '../models/punto_ayuda.dart';
import '../models/tipo_incidencia.dart';
import 'crisis_repository.dart';

/// Lista en memoria que emite su contenido cada vez que cambia.
class _Coleccion<T> {
  _Coleccion([List<T>? iniciales]) : items = iniciales ?? [];

  final List<T> items;
  final _cambios = StreamController<List<T>>.broadcast();

  /// Cada oyente recibe el contenido actual y luego los cambios, como en
  /// Firestore. Se puede escuchar varias veces.
  Stream<List<T>> stream() => Stream.multi((oyente) {
        oyente.add(List.unmodifiable(items));
        final sub = _cambios.stream.listen(oyente.add, onError: oyente.addError);
        oyente.onCancel = sub.cancel;
      });

  void notificar() => _cambios.add(List.unmodifiable(items));
}

/// Repositorio en memoria con datos de ejemplo alrededor del centro de Madrid.
///
/// Permite probar y enseñar la app sin cuenta de Firebase. Los datos se
/// pierden al cerrar la app.
class DemoRepository implements CrisisRepository {
  DemoRepository() {
    _sembrarDatos();
  }

  int _siguienteId = 1;
  String _nuevoId() => 'demo-${_siguienteId++}';

  final _incidencias = _Coleccion<Incidencia>();
  final _ayudas = _Coleccion<PuntoAyuda>();
  final _donaciones = _Coleccion<Donacion>();
  final Map<String, _Coleccion<FotoIncidencia>> _fotos = {};

  _Coleccion<FotoIncidencia> _fotosDe(String id) => _fotos.putIfAbsent(id, _Coleccion.new);

  /// Simula la latencia de red para que la interfaz se comporte igual que con Firestore.
  Future<void> _latencia() => Future.delayed(const Duration(milliseconds: 250));

  void _sembrarDatos() {
    final ahora = DateTime.now();

    _incidencias.items.addAll([
      Incidencia(
        id: _nuevoId(),
        tipo: TipoIncidencia.calle_cortada,
        titulo: 'Gran Vía cortada por desprendimiento',
        descripcion: 'Cornisa caída sobre la calzada. Bomberos trabajando en la zona.',
        gravedad: Gravedad.alta,
        fecha: ahora.subtract(const Duration(minutes: 25)),
        userId: 'demo-vecino',
        autor: 'Vecina del barrio (demo)',
        inicio: const LatLng(40.42030, -3.70580),
        fin: const LatLng(40.41965, -3.70150),
      ),
      Incidencia(
        id: _nuevoId(),
        tipo: TipoIncidencia.inundacion,
        titulo: 'Desbordamiento junto a Madrid Río',
        descripcion: 'El agua cubre el paseo y los accesos peatonales. No cruzar.',
        gravedad: Gravedad.media,
        fecha: ahora.subtract(const Duration(hours: 2)),
        userId: 'demo-voluntario',
        autor: 'Voluntario (demo)',
        vertices: const [
          LatLng(40.40330, -3.72150),
          LatLng(40.40480, -3.71650),
          LatLng(40.40150, -3.71450),
          LatLng(40.39980, -3.71950),
        ],
      ),
      Incidencia(
        id: _nuevoId(),
        tipo: TipoIncidencia.incendio,
        titulo: 'Incendio de vegetación en Casa de Campo',
        descripcion: 'Columna de humo visible. Zona acordonada.',
        gravedad: Gravedad.alta,
        fecha: ahora.subtract(const Duration(hours: 5)),
        userId: 'demo-vecino',
        autor: 'Vecina del barrio (demo)',
        centro: const LatLng(40.41900, -3.74800),
        radio: 600,
      ),
      Incidencia(
        id: _nuevoId(),
        tipo: TipoIncidencia.zona_terremoto,
        titulo: 'Grietas en edificios tras el temblor',
        descripcion: 'Varios portales desalojados de forma preventiva.',
        gravedad: Gravedad.media,
        fecha: ahora.subtract(const Duration(days: 1)),
        userId: 'demo-voluntario',
        autor: 'Voluntario (demo)',
        centro: const LatLng(40.43300, -3.68900),
        radio: 450,
      ),
    ]);

    _ayudas.items.addAll([
      PuntoAyuda(
        id: _nuevoId(),
        tipo: TipoAyuda.punto_encuentro,
        nombre: 'Plaza Mayor',
        descripcion: 'Punto de encuentro para personas desalojadas del centro.',
        posicion: const LatLng(40.41553, -3.70742),
        fecha: ahora.subtract(const Duration(hours: 1)),
        userId: 'demo-voluntario',
        autor: 'Voluntario (demo)',
      ),
      PuntoAyuda(
        id: _nuevoId(),
        tipo: TipoAyuda.albergue,
        nombre: 'Polideportivo municipal (albergue temporal)',
        descripcion: '120 camas, mantas y comida caliente. Se admiten mascotas.',
        contacto: 'Abierto 24 h',
        posicion: const LatLng(40.41100, -3.69950),
        fecha: ahora.subtract(const Duration(hours: 3)),
        userId: 'demo-voluntario',
        autor: 'Voluntario (demo)',
      ),
      PuntoAyuda(
        id: _nuevoId(),
        tipo: TipoAyuda.agua_comida,
        nombre: 'Reparto de agua embotellada',
        descripcion: 'Agua y bocadillos hasta agotar existencias.',
        contacto: 'De 9:00 a 21:00',
        posicion: const LatLng(40.42350, -3.71200),
        fecha: ahora.subtract(const Duration(hours: 4)),
        userId: 'demo-vecino',
        autor: 'Vecina del barrio (demo)',
      ),
      PuntoAyuda(
        id: _nuevoId(),
        tipo: TipoAyuda.sanitario,
        nombre: 'Puesto sanitario avanzado',
        descripcion: 'Primeros auxilios y atención a heridos leves.',
        posicion: const LatLng(40.41850, -3.69600),
        fecha: ahora.subtract(const Duration(hours: 2)),
        userId: 'demo-voluntario',
        autor: 'Voluntario (demo)',
      ),
      PuntoAyuda(
        id: _nuevoId(),
        tipo: TipoAyuda.recogida_donaciones,
        nombre: 'Recogida de ropa y mantas',
        descripcion: 'Se necesita ropa de abrigo, mantas y productos de higiene.',
        contacto: 'Parroquia del barrio, de 10:00 a 20:00',
        posicion: const LatLng(40.41300, -3.71000),
        fecha: ahora.subtract(const Duration(hours: 6)),
        userId: 'demo-vecino',
        autor: 'Vecina del barrio (demo)',
      ),
    ]);

    _donaciones.items.addAll([
      Donacion(
        id: _nuevoId(),
        clase: ClaseDonacion.necesito,
        categoria: CategoriaDonacion.ropa,
        descripcion: 'Mantas y ropa de abrigo para 30 personas en el albergue.',
        contacto: 'Preguntar en el polideportivo',
        zona: 'Centro',
        fecha: ahora.subtract(const Duration(hours: 1)),
        userId: 'demo-voluntario',
        autor: 'Voluntario (demo)',
      ),
      Donacion(
        id: _nuevoId(),
        clase: ClaseDonacion.ofrezco,
        categoria: CategoriaDonacion.transporte,
        descripcion: 'Furgoneta disponible para trasladar material esta tarde.',
        contacto: 'Mensaje por la app',
        zona: 'Arganzuela',
        fecha: ahora.subtract(const Duration(hours: 3)),
        userId: 'demo-vecino',
        autor: 'Vecina del barrio (demo)',
      ),
      Donacion(
        id: _nuevoId(),
        clase: ClaseDonacion.ofrezco,
        categoria: CategoriaDonacion.alojamiento,
        descripcion: 'Habitación libre para una familia durante una semana.',
        zona: 'Chamberí',
        fecha: ahora.subtract(const Duration(days: 1)),
        userId: 'demo-vecino',
        autor: 'Vecina del barrio (demo)',
      ),
    ]);
  }

  // — Incidencias —

  @override
  Stream<List<Incidencia>> incidencias() => _incidencias.stream();

  @override
  Future<String> crearIncidencia(Incidencia incidencia) async {
    await _latencia();
    final nueva = incidencia.copyWith(id: _nuevoId());
    _incidencias.items.insert(0, nueva);
    _incidencias.notificar();
    return nueva.id;
  }

  @override
  Future<void> marcarIncidenciaActiva(String id, bool activa) async {
    await _latencia();
    final i = _incidencias.items.indexWhere((e) => e.id == id);
    if (i == -1) return;
    _incidencias.items[i] = _incidencias.items[i].copyWith(activa: activa);
    _incidencias.notificar();
  }

  @override
  Future<void> borrarIncidencia(String id) async {
    await _latencia();
    _incidencias.items.removeWhere((e) => e.id == id);
    _fotos.remove(id);
    _incidencias.notificar();
  }

  // — Fotos —

  @override
  Stream<List<FotoIncidencia>> fotos(String incidenciaId) => _fotosDe(incidenciaId).stream();

  @override
  Future<void> anadirFoto(String incidenciaId, FotoIncidencia foto) async {
    await _latencia();
    final coleccion = _fotosDe(incidenciaId);
    coleccion.items.add(FotoIncidencia(
      id: _nuevoId(),
      bytes: foto.bytes,
      fecha: foto.fecha,
      userId: foto.userId,
      autor: foto.autor,
    ));
    coleccion.notificar();
  }

  // — Puntos de ayuda —

  @override
  Stream<List<PuntoAyuda>> puntosAyuda() => _ayudas.stream();

  @override
  Future<void> crearPuntoAyuda(PuntoAyuda punto) async {
    await _latencia();
    _ayudas.items.insert(0, punto.copyWith(id: _nuevoId()));
    _ayudas.notificar();
  }

  @override
  Future<void> borrarPuntoAyuda(String id) async {
    await _latencia();
    _ayudas.items.removeWhere((e) => e.id == id);
    _ayudas.notificar();
  }

  // — Donaciones —

  @override
  Stream<List<Donacion>> donaciones() => _donaciones.stream();

  @override
  Future<void> crearDonacion(Donacion donacion) async {
    await _latencia();
    _donaciones.items.insert(0, donacion.copyWith(id: _nuevoId()));
    _donaciones.notificar();
  }

  @override
  Future<void> marcarDonacionCubierta(String id, bool cubierta) async {
    await _latencia();
    final i = _donaciones.items.indexWhere((e) => e.id == id);
    if (i == -1) return;
    _donaciones.items[i] = _donaciones.items[i].copyWith(cubierta: cubierta);
    _donaciones.notificar();
  }

  @override
  Future<void> borrarDonacion(String id) async {
    await _latencia();
    _donaciones.items.removeWhere((e) => e.id == id);
    _donaciones.notificar();
  }
}
