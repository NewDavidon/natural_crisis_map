import 'dart:convert';
import 'dart:typed_data';

/// Foto adjunta a una incidencia.
///
/// Se guarda como JPEG comprimido en base64 dentro de Firestore
/// (subcolección `incidencias/{id}/fotos`), así no hace falta Firebase
/// Storage ni el plan de pago.
class FotoIncidencia {
  /// Tamaño máximo de una foto en base64 (los documentos de Firestore
  /// tienen un límite de 1 MiB).
  static const int maxBytesBase64 = 900 * 1024;

  final String id;
  final Uint8List bytes;
  final DateTime fecha;
  final String userId;
  final String autor;

  const FotoIncidencia({
    required this.id,
    required this.bytes,
    required this.fecha,
    required this.userId,
    this.autor = '',
  });

  /// Indica si unos bytes caben en un documento de Firestore.
  static bool cabeEnFirestore(Uint8List bytes) =>
      base64Encode(bytes).length <= maxBytesBase64;

  factory FotoIncidencia.fromMap(Map<String, dynamic> map, String docId) {
    return FotoIncidencia(
      id: docId,
      bytes: base64Decode(map['data'] as String? ?? ''),
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
      userId: map['userId'] as String? ?? '',
      autor: map['autor'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'data': base64Encode(bytes),
        'fecha': fecha.toIso8601String(),
        'userId': userId,
        'autor': autor,
      };
}
