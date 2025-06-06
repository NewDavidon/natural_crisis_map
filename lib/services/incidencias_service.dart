import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/incidencia.dart';
import '../models/tipo_incidencia.dart';
import 'package:latlong2/latlong.dart';


/// Servicio que simula operaciones CRUD para incidencias
class IncidenciasService {
  final _uuid = const Uuid();  // Generador de IDs

  // Datos mock iniciales (5 incidencias)
  final List<Incidencia> _mockData = List.generate(5, (i) {
    final now = DateTime.now().subtract(Duration(days: i));

    // Para cada incidencia de ejemplo, asignamos un tipo cíclicamente
    final tipos = TipoIncidencia.values;
    final tipoEjemplo = tipos[i % tipos.length];

    return Incidencia(
      id: const Uuid().v4(),
      tipo: tipoEjemplo,
      titulo: 'Incidencia #${i + 1}',
      descripcion: 'Descripción incidencia ${i + 1}',
      // Para mock, asignamos puntos simples
      inicio: tipoEjemplo == TipoIncidencia.calle_cortada
          ? LatLng(40.4168 + i * 0.01, -3.7038 - i * 0.01)
          : null,
      fin: tipoEjemplo == TipoIncidencia.calle_cortada
          ? LatLng(40.4170 + i * 0.01, -3.7040 - i * 0.01)
          : null,
      centro: tipoEjemplo == TipoIncidencia.zona_terremoto
          ? LatLng(40.4168 + i * 0.02, -3.7038 - i * 0.02)
          : null,
      radio: tipoEjemplo == TipoIncidencia.zona_terremoto
          ? 500.0 + i * 100
          : null,
      vertices: tipoEjemplo == TipoIncidencia.inundacion
          ? [
              LatLng(40.4168 + i * 0.01, -3.7038 - i * 0.01),
              LatLng(40.4170 + i * 0.01, -3.7040 - i * 0.01),
              LatLng(40.4172 + i * 0.01, -3.7036 - i * 0.01),
              LatLng(40.4169 + i * 0.01, -3.7034 - i * 0.01),
            ]
          : null,
      fecha: now,
      userId: 'user_${i + 1}',
    );
  });

  /// Emite la lista de incidencias cada 5 segundos, simulando real-time
  Stream<List<Incidencia>> obtenerIncidencias() {
    return Stream<List<Incidencia>>.periodic(
      const Duration(seconds: 5),
      (_) => List<Incidencia>.from(_mockData),
    ).asBroadcastStream(); // Permite múltiples escuchas
  }

  /// Crea y añade una nueva incidencia
  Future<void> crearIncidencia(Incidencia inc) async {
    final nueva = Incidencia(
      id: _uuid.v4(),
      tipo: inc.tipo,
      titulo: inc.titulo,
      descripcion: inc.descripcion,
      inicio: inc.inicio,
      fin: inc.fin,
      centro: inc.centro,
      radio: inc.radio,
      vertices: inc.vertices,
      fecha: inc.fecha,
      userId: inc.userId,
    );
    _mockData.add(nueva);
    await Future.delayed(const Duration(milliseconds: 300)); // Simula latencia
  }

  /// Actualiza un reporte existente según su ID
  Future<void> actualizarIncidencia(Incidencia inc) async {
    final idx = _mockData.indexWhere((e) => e.id == inc.id);
    if (idx != -1) {
      _mockData[idx] = inc;
    }
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Elimina un reporte dado su ID
  Future<void> borrarIncidencia(String id) async {
    _mockData.removeWhere((e) => e.id == id);
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
