// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Tipos de punto de ayuda que se pueden marcar en el mapa.
enum TipoAyuda {
  albergue,
  agua_comida,
  sanitario,
  recogida_donaciones,
  punto_encuentro,
  otro,
}

extension TipoAyudaInfo on TipoAyuda {
  String get etiqueta => switch (this) {
        TipoAyuda.albergue => 'Albergue / refugio',
        TipoAyuda.agua_comida => 'Agua y comida',
        TipoAyuda.sanitario => 'Atención sanitaria',
        TipoAyuda.recogida_donaciones => 'Recogida de donaciones',
        TipoAyuda.punto_encuentro => 'Punto de encuentro',
        TipoAyuda.otro => 'Otra ayuda',
      };

  IconData get icono => switch (this) {
        TipoAyuda.albergue => Icons.night_shelter,
        TipoAyuda.agua_comida => Icons.restaurant,
        TipoAyuda.sanitario => Icons.local_hospital,
        TipoAyuda.recogida_donaciones => Icons.volunteer_activism,
        TipoAyuda.punto_encuentro => Icons.groups,
        TipoAyuda.otro => Icons.support,
      };

  Color get color => switch (this) {
        TipoAyuda.albergue => const Color(0xFF6A1B9A),
        TipoAyuda.agua_comida => const Color(0xFF00838F),
        TipoAyuda.sanitario => const Color(0xFFC2185B),
        TipoAyuda.recogida_donaciones => const Color(0xFF2E7D32),
        TipoAyuda.punto_encuentro => const Color(0xFF283593),
        TipoAyuda.otro => const Color(0xFF546E7A),
      };
}

/// Lugar donde se ofrece ayuda: albergues, reparto de agua, sanitarios…
class PuntoAyuda {
  final String id;
  final TipoAyuda tipo;
  final String nombre;
  final String descripcion;
  final String contacto;             // Teléfono, horario, responsable…
  final LatLng posicion;
  final DateTime fecha;
  final String userId;
  final String autor;

  const PuntoAyuda({
    required this.id,
    required this.tipo,
    required this.nombre,
    required this.posicion,
    required this.fecha,
    required this.userId,
    this.descripcion = '',
    this.contacto = '',
    this.autor = '',
  });

  PuntoAyuda copyWith({String? id}) => PuntoAyuda(
        id: id ?? this.id,
        tipo: tipo,
        nombre: nombre,
        descripcion: descripcion,
        contacto: contacto,
        posicion: posicion,
        fecha: fecha,
        userId: userId,
        autor: autor,
      );

  factory PuntoAyuda.fromMap(Map<String, dynamic> map, String docId) {
    return PuntoAyuda(
      id: docId,
      tipo: TipoAyuda.values.firstWhere(
        (t) => t.name == map['tipo'],
        orElse: () => TipoAyuda.otro,
      ),
      nombre: map['nombre'] as String? ?? '',
      descripcion: map['descripcion'] as String? ?? '',
      contacto: map['contacto'] as String? ?? '',
      posicion: LatLng(
        (map['lat'] as num? ?? 0).toDouble(),
        (map['lng'] as num? ?? 0).toDouble(),
      ),
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
      userId: map['userId'] as String? ?? '',
      autor: map['autor'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'tipo': tipo.name,
        'nombre': nombre,
        'descripcion': descripcion,
        'contacto': contacto,
        'lat': posicion.latitude,
        'lng': posicion.longitude,
        'fecha': fecha.toIso8601String(),
        'userId': userId,
        'autor': autor,
      };
}
