import 'package:uuid/uuid.dart';
import '../models/incidencia.dart';
import '../models/tipo_incidencia.dart';
import 'package:latlong2/latlong.dart';

/// Servicio singleton para guardar incidencias en un vector temporal.
class PendingIncidentsService {
  PendingIncidentsService._();
  static final instance = PendingIncidentsService._();

  final List<Incidencia> _pending = [];
  final _uuid = const Uuid();

  /// Añade una incidencia en memoria con todos los campos necesarios.
  /// Dependiendo de [tipo], se pasarán los parámetros de ubicación adecuados:
  ///  - calle_cortada: requiere `inicio` y `fin`.
  ///  - zona_terremoto: requiere `centro` y `radio`.
  ///  - inundacion: requiere lista de 4 `vertices`.
  void add({
    required TipoIncidencia tipo,
    required String titulo,
    required String descripcion,
    // Campos opcionales para ubicación:
    LatLng? inicio,
    LatLng? fin,
    LatLng? centro,
    double? radio,
    List<LatLng>? vertices,
    required DateTime fecha,
    required String userId,
  }) {
    // Construimos el objeto Incidencia; el constructor validará internamente.
    final nueva = Incidencia(
      id: _uuid.v4(),
      tipo: tipo,
      titulo: titulo,
      descripcion: descripcion,
      fecha: fecha,
      userId: userId,
      inicio: inicio,
      fin: fin,
      centro: centro,
      radio: radio,
      vertices: vertices,
    );

    // Si no arroja excepción, lo agregamos a la lista de pendientes.
    _pending.add(nueva);
  }

  /// Devuelve la lista inmutable de incidencias pendientes.
  List<Incidencia> get all => List.unmodifiable(_pending);

  /// Elimina todas las incidencias pendientes.
  void clear() => _pending.clear();

  /// Elimina un borrador concreto por ID.
  void removeById(String id) {
    _pending.removeWhere((inc) => inc.id == id);
  }
}
