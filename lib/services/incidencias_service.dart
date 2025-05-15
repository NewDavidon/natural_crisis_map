import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/incidencia.dart';

// Servicio que simula operaciones CRUD para incidencias
class IncidenciasService {
  final _uuid = const Uuid();  // Generador de IDs

  // Datos mock iniciales (5 incidencias)
  final List<Incidencia> _mockData = List.generate(5, (i) {
    final now = DateTime.now().subtract(Duration(days: i));
    return Incidencia(
      id: const Uuid().v4(),
      titulo: 'Incidencia #${i + 1}',
      descripcion: 'Descripción incidencia ${i + 1}',
      lat: 40.4168 + i * 0.01,
      lng: -3.7038 - i * 0.01,
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
      titulo: inc.titulo,
      descripcion: inc.descripcion,
      lat: inc.lat,
      lng: inc.lng,
      fecha: inc.fecha,
      userId: inc.userId,
    );
    _mockData.add(nueva);
    await Future.delayed(const Duration(milliseconds: 300)); // Simula latencia
  }

  /// Actualiza un reporte existente según su ID
  Future<void> actualizarIncidencia(Incidencia inc) async {
    final idx = _mockData.indexWhere((e) => e.id == inc.id);
    if (idx != -1) _mockData[idx] = inc;
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Elimina un reporte dado su ID
  Future<void> borrarIncidencia(String id) async {
    _mockData.removeWhere((e) => e.id == id);
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
