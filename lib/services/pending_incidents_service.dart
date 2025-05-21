// lib/services/pending_incidents_service.dart

import 'package:uuid/uuid.dart';
import '../models/incidencia.dart';

/// Servicio singleton para guardar incidencias en un vector temporal.
class PendingIncidentsService {
  PendingIncidentsService._();
  static final instance = PendingIncidentsService._();

  final List<Incidencia> _pending = [];
  final _uuid = const Uuid();

  /// Añade una incidencia con título y descripción. Lat/lng y userId se completarán después.
  void add({required String titulo, required String descripcion}) {
    _pending.add(
      Incidencia(
        id: _uuid.v4(),
        titulo: titulo,
        descripcion: descripcion,
        lat: 0.0,
        lng: 0.0,
        fecha: DateTime.now(),
        userId: 'pending',
      ),
    );
  }

  /// Devuelve la lista inmutable de incidencias pendientes.
  List<Incidencia> get all => List.unmodifiable(_pending);

  /// Limpia todas las incidencias pendientes (opcional).
  void clear() => _pending.clear();
}
