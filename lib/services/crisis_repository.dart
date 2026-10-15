import '../models/donacion.dart';
import '../models/foto_incidencia.dart';
import '../models/incidencia.dart';
import '../models/punto_ayuda.dart';

/// Acceso a los datos compartidos de la app.
///
/// Hay dos implementaciones:
///   • `FirestoreRepository`: datos reales en Cloud Firestore.
///   • `DemoRepository`: datos en memoria para probar la app sin conexión.
abstract class CrisisRepository {
  // — Incidencias —
  /// Todas las incidencias, de la más reciente a la más antigua.
  Stream<List<Incidencia>> incidencias();

  /// Guarda una incidencia nueva y devuelve su ID.
  Future<String> crearIncidencia(Incidencia incidencia);

  Future<void> marcarIncidenciaActiva(String id, bool activa);

  /// Borra una incidencia junto con sus fotos.
  Future<void> borrarIncidencia(String id);

  // — Fotos de una incidencia —
  Stream<List<FotoIncidencia>> fotos(String incidenciaId);

  Future<void> anadirFoto(String incidenciaId, FotoIncidencia foto);

  // — Puntos de ayuda —
  Stream<List<PuntoAyuda>> puntosAyuda();

  Future<void> crearPuntoAyuda(PuntoAyuda punto);

  Future<void> borrarPuntoAyuda(String id);

  // — Tablón de donaciones —
  Stream<List<Donacion>> donaciones();

  Future<void> crearDonacion(Donacion donacion);

  Future<void> marcarDonacionCubierta(String id, bool cubierta);

  Future<void> borrarDonacion(String id);
}
