// Representa un reporte de incidencia con todos sus datos
class Incidencia {
  final String id;            // ID único (docId en Firestore o UUID en mock)
  final String titulo;        // Título breve de la incidencia
  final String descripcion;   // Detalle más completo
  final double lat;           // Latitud de la ubicación
  final double lng;           // Longitud de la ubicación
  final DateTime fecha;       // Fecha y hora de creación
  final String userId;        // ID del usuario que creó el reporte

  // Constructor principal usando parámetros nombrados
  Incidencia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.lat,
    required this.lng,
    required this.fecha,
    required this.userId,
  });

  /// Crea una Incidencia a partir de un Map (por ejemplo de Firestore)
  factory Incidencia.fromMap(Map<String, dynamic> map, String docId) {
    return Incidencia(
      id: docId,
      titulo: map['titulo'] as String? ?? '',
      descripcion: map['descripcion'] as String? ?? '',
      lat: map['lat'] as double? ?? 0.0,
      lng: map['lng'] as double? ?? 0.0,
      fecha: (map['fecha'] as DateTime?) ?? DateTime.now(),
      userId: map['userId'] as String? ?? '',
    );
  }

  /// Convierte la instancia en un Map para enviar a Firestore
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'lat': lat,
      'lng': lng,
      'fecha': fecha,
      'userId': userId,
    };
  }
}
