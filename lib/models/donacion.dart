import 'package:flutter/material.dart';

/// Si el usuario ofrece algo o lo necesita.
enum ClaseDonacion { ofrezco, necesito }

extension ClaseDonacionInfo on ClaseDonacion {
  String get etiqueta => switch (this) {
        ClaseDonacion.ofrezco => 'Ofrezco',
        ClaseDonacion.necesito => 'Necesito',
      };

  Color get color => switch (this) {
        ClaseDonacion.ofrezco => const Color(0xFF2E7D32),
        ClaseDonacion.necesito => const Color(0xFFE65100),
      };
}

/// Qué se ofrece o se necesita.
enum CategoriaDonacion {
  agua,
  alimentos,
  ropa,
  medicinas,
  higiene,
  alojamiento,
  transporte,
  voluntariado,
  otros,
}

extension CategoriaDonacionInfo on CategoriaDonacion {
  String get etiqueta => switch (this) {
        CategoriaDonacion.agua => 'Agua',
        CategoriaDonacion.alimentos => 'Alimentos',
        CategoriaDonacion.ropa => 'Ropa y mantas',
        CategoriaDonacion.medicinas => 'Medicinas',
        CategoriaDonacion.higiene => 'Higiene',
        CategoriaDonacion.alojamiento => 'Alojamiento',
        CategoriaDonacion.transporte => 'Transporte',
        CategoriaDonacion.voluntariado => 'Voluntariado',
        CategoriaDonacion.otros => 'Otros',
      };

  IconData get icono => switch (this) {
        CategoriaDonacion.agua => Icons.water_drop,
        CategoriaDonacion.alimentos => Icons.lunch_dining,
        CategoriaDonacion.ropa => Icons.checkroom,
        CategoriaDonacion.medicinas => Icons.medication,
        CategoriaDonacion.higiene => Icons.soap,
        CategoriaDonacion.alojamiento => Icons.bed,
        CategoriaDonacion.transporte => Icons.directions_car,
        CategoriaDonacion.voluntariado => Icons.handshake,
        CategoriaDonacion.otros => Icons.inventory_2,
      };
}

/// Publicación del tablón solidario: alguien ofrece o necesita algo.
class Donacion {
  final String id;
  final ClaseDonacion clase;
  final CategoriaDonacion categoria;
  final String descripcion;
  final String contacto;
  final String zona;                 // Barrio, calle o referencia
  final DateTime fecha;
  final String userId;
  final String autor;
  final bool cubierta;               // Ya se ha entregado / resuelto

  const Donacion({
    required this.id,
    required this.clase,
    required this.categoria,
    required this.descripcion,
    required this.fecha,
    required this.userId,
    this.contacto = '',
    this.zona = '',
    this.autor = '',
    this.cubierta = false,
  });

  Donacion copyWith({String? id, bool? cubierta}) => Donacion(
        id: id ?? this.id,
        clase: clase,
        categoria: categoria,
        descripcion: descripcion,
        contacto: contacto,
        zona: zona,
        fecha: fecha,
        userId: userId,
        autor: autor,
        cubierta: cubierta ?? this.cubierta,
      );

  factory Donacion.fromMap(Map<String, dynamic> map, String docId) {
    return Donacion(
      id: docId,
      clase: ClaseDonacion.values.firstWhere(
        (c) => c.name == map['clase'],
        orElse: () => ClaseDonacion.ofrezco,
      ),
      categoria: CategoriaDonacion.values.firstWhere(
        (c) => c.name == map['categoria'],
        orElse: () => CategoriaDonacion.otros,
      ),
      descripcion: map['descripcion'] as String? ?? '',
      contacto: map['contacto'] as String? ?? '',
      zona: map['zona'] as String? ?? '',
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
      userId: map['userId'] as String? ?? '',
      autor: map['autor'] as String? ?? '',
      cubierta: map['cubierta'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'clase': clase.name,
        'categoria': categoria.name,
        'descripcion': descripcion,
        'contacto': contacto,
        'zona': zona,
        'fecha': fecha.toIso8601String(),
        'userId': userId,
        'autor': autor,
        'cubierta': cubierta,
      };
}
