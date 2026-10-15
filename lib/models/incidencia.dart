import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'tipo_incidencia.dart';

/// Nivel de gravedad de una incidencia.
enum Gravedad { baja, media, alta }

extension GravedadInfo on Gravedad {
  String get etiqueta => switch (this) {
        Gravedad.baja => 'Baja',
        Gravedad.media => 'Media',
        Gravedad.alta => 'Alta',
      };

  Color get color => switch (this) {
        Gravedad.baja => const Color(0xFF2E7D32),
        Gravedad.media => const Color(0xFFF9A825),
        Gravedad.alta => const Color(0xFFC62828),
      };
}

/// Representa un reporte de incidencia con todos sus datos.
///
/// Dependiendo de la geometría de [tipo], sólo se rellenan ciertos campos de
/// ubicación:
///   • línea (calle cortada): [inicio] y [fin].
///   • círculo (terremoto, incendio): [centro] y [radio].
///   • polígono (inundación): [vertices] con 3 o más puntos.
///
/// Las fotos se guardan aparte (ver `FotoIncidencia`) para que el documento
/// de la incidencia sea ligero.
class Incidencia {
  final String id;                   // ID único (docId en Firestore o UUID en demo)
  final TipoIncidencia tipo;         // Tipo de incidencia (enum)
  final String titulo;               // Título breve de la incidencia
  final String descripcion;          // Detalle más completo
  final Gravedad gravedad;           // Nivel de gravedad
  final DateTime fecha;              // Fecha y hora de creación
  final String userId;               // ID del usuario que creó el reporte
  final String autor;                // Nombre visible del autor
  final bool activa;                 // false cuando el autor la marca como resuelta

  // — Campos de ubicación (sólo uno de estos grupos se usará, según tipo) —
  final LatLng? inicio;              // línea: inicio del tramo
  final LatLng? fin;                 // línea: fin del tramo
  final LatLng? centro;              // círculo: centro de la zona afectada
  final double? radio;               // círculo: radio de afectación (metros)
  final List<LatLng>? vertices;      // polígono: vértices de la zona

  Incidencia({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.userId,
    this.autor = '',
    this.gravedad = Gravedad.media,
    this.activa = true,
    this.inicio,
    this.fin,
    this.centro,
    this.radio,
    this.vertices,
  }) {
    // Validación mínima: según la geometría, los campos obligatorios no pueden ser null.
    switch (tipo.geometria) {
      case GeometriaZona.linea:
        if (inicio == null || fin == null) {
          throw ArgumentError('Para ${tipo.etiqueta} debes indicar "inicio" y "fin".');
        }
      case GeometriaZona.circulo:
        if (centro == null || radio == null || radio! <= 0) {
          throw ArgumentError('Para ${tipo.etiqueta} debes indicar "centro" y un "radio" positivo.');
        }
      case GeometriaZona.poligono:
        if ((vertices?.length ?? 0) < 3) {
          throw ArgumentError('Para ${tipo.etiqueta} debes indicar al menos 3 vértices.');
        }
    }
  }

  /// Punto representativo de la incidencia (donde se pinta su icono).
  LatLng get posicion {
    switch (tipo.geometria) {
      case GeometriaZona.linea:
        return LatLng(
          (inicio!.latitude + fin!.latitude) / 2,
          (inicio!.longitude + fin!.longitude) / 2,
        );
      case GeometriaZona.circulo:
        return centro!;
      case GeometriaZona.poligono:
        final vs = vertices!;
        final lat = vs.map((v) => v.latitude).reduce((a, b) => a + b) / vs.length;
        final lng = vs.map((v) => v.longitude).reduce((a, b) => a + b) / vs.length;
        return LatLng(lat, lng);
    }
  }

  Incidencia copyWith({String? id, bool? activa}) {
    return Incidencia(
      id: id ?? this.id,
      tipo: tipo,
      titulo: titulo,
      descripcion: descripcion,
      gravedad: gravedad,
      fecha: fecha,
      userId: userId,
      autor: autor,
      activa: activa ?? this.activa,
      inicio: inicio,
      fin: fin,
      centro: centro,
      radio: radio,
      vertices: vertices,
    );
  }

  /// Crea una Incidencia a partir de un Map (por ejemplo, de Firestore).
  ///
  /// Se espera que el Map contenga:
  ///   • "tipo" (string) → se convierte a enum.
  ///   • "titulo", "descripcion", "gravedad", "fecha" (ISO string), "userId",
  ///     "autor" y "activa".
  ///   • Además, según la geometría:
  ///       – línea: "inicioLat", "inicioLng", "finLat", "finLng".
  ///       – círculo: "centroLat", "centroLng", "radio".
  ///       – polígono: "vertices" → lista de {lat, lng}
  ///         (también se acepta el formato antiguo v0Lat/v0Lng … v3Lat/v3Lng).
  factory Incidencia.fromMap(Map<String, dynamic> map, String docId) {
    double? num_(String key) => (map[key] as num?)?.toDouble();
    LatLng? punto(String lat, String lng) {
      final a = num_(lat), b = num_(lng);
      return (a == null || b == null) ? null : LatLng(a, b);
    }

    final tipo = tipoFromString(map['tipo'] as String? ?? '');

    List<LatLng>? vertices;
    final rawVertices = map['vertices'];
    if (rawVertices is List) {
      vertices = rawVertices
          .whereType<Map>()
          .map((v) => LatLng((v['lat'] as num).toDouble(), (v['lng'] as num).toDouble()))
          .toList();
    } else if (map.containsKey('v0Lat')) {
      vertices = [
        for (int i = 0; map.containsKey('v${i}Lat'); i++) punto('v${i}Lat', 'v${i}Lng')!,
      ];
    }

    return Incidencia(
      id: docId,
      tipo: tipo,
      titulo: map['titulo'] as String? ?? '',
      descripcion: map['descripcion'] as String? ?? '',
      gravedad: Gravedad.values.firstWhere(
        (g) => g.name == map['gravedad'],
        orElse: () => Gravedad.media,
      ),
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
      userId: map['userId'] as String? ?? '',
      autor: map['autor'] as String? ?? '',
      activa: map['activa'] as bool? ?? true,
      inicio: punto('inicioLat', 'inicioLng'),
      fin: punto('finLat', 'finLng'),
      centro: punto('centroLat', 'centroLng'),
      radio: num_('radio'),
      vertices: vertices,
    );
  }

  /// Convierte la instancia a Map para persistir (por ejemplo, en Firestore).
  /// Incluye sólo los campos de ubicación relevantes según [tipo].
  Map<String, dynamic> toMap() {
    final base = <String, dynamic>{
      'tipo': tipoToString(tipo),
      'titulo': titulo,
      'descripcion': descripcion,
      'gravedad': gravedad.name,
      'fecha': fecha.toIso8601String(),
      'userId': userId,
      'autor': autor,
      'activa': activa,
    };

    switch (tipo.geometria) {
      case GeometriaZona.linea:
        base['inicioLat'] = inicio!.latitude;
        base['inicioLng'] = inicio!.longitude;
        base['finLat']    = fin!.latitude;
        base['finLng']    = fin!.longitude;
      case GeometriaZona.circulo:
        base['centroLat'] = centro!.latitude;
        base['centroLng'] = centro!.longitude;
        base['radio']     = radio!;
      case GeometriaZona.poligono:
        base['vertices'] = [
          for (final v in vertices!) {'lat': v.latitude, 'lng': v.longitude},
        ];
    }

    return base;
  }
}
