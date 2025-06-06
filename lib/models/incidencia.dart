import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'tipo_incidencia.dart';

/// Representa un reporte de incidencia con todos sus datos.
/// 
/// Dependiendo de [tipo], sólo deben rellenarse ciertos campos de ubicación:
///   • calle_cortada: [inicio] y [fin] no nulos; los demás null.
///   • zona_terremoto: [centro] y [radio] no nulos; los demás null.
///   • inundacion: [vertices] es una lista de 4 LatLng; los demás null.
/// 
class Incidencia {
  final String id;                   // ID único (docId en Firestore o UUID en mock)
  final TipoIncidencia tipo;         // Tipo de incidencia (enum)
  final String titulo;               // Título breve de la incidencia
  final String descripcion;          // Detalle más completo
  final DateTime fecha;              // Fecha y hora de creación
  final String userId;               // ID del usuario que creó el reporte

  // — Campos de ubicación (sólo uno de estos grupos se usará, según tipo) —

  // 1) Para calle_cortada:
  final LatLng? inicio;              // coordenada de inicio de calle cortada
  final LatLng? fin;                 // coordenada de fin de calle cortada

  // 2) Para zona_terremoto:
  final LatLng? centro;              // centro de la zona afectada
  final double? radio;               // radio de afectación (en metros)

  // 3) Para inundacion:
  final List<LatLng>? vertices;      // lista de 4 vértices (polígono)

  Incidencia({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.userId,
    this.inicio,
    this.fin,
    this.centro,
    this.radio,
    this.vertices,
  }) {
    // Validación mínima: según tipo, los campos obligatorios no pueden ser null.
    switch (tipo) {
      case TipoIncidencia.calle_cortada:
        if (inicio == null || fin == null) {
          throw Exception(
            'Para calle_cortada debes proporcionar "inicio" y "fin".',
          );
        }
        break;

      case TipoIncidencia.zona_terremoto:
        if (centro == null || radio == null) {
          throw Exception(
            'Para zona_terremoto debes proporcionar "centro" y "radio".',
          );
        }
        break;

      case TipoIncidencia.inundacion:
        // Usamos el acceso condicional `?.length`
        if (vertices?.length != 4) {
          throw Exception(
            'Para inundacion debes proporcionar exactamente 4 vértices.',
          );
        }
        break;
    }
  }

  /// Crea una Incidencia a partir de un Map (por ejemplo, de Firestore o de un servicio REST).
  /// 
  /// Se espera que el Map contenga:
  ///   • "tipo" (string) → se convierte a enum.
  ///   • "titulo", "descripcion", "fecha" (en ISO string) y "userId".
  ///   • Además, según el tipo:
  ///       – calle_cortada: "inicioLat", "inicioLng", "finLat", "finLng".
  ///       – zona_terremoto: "centroLat", "centroLng", "radio".
  ///       – inundacion: “v0Lat”, “v0Lng”, …, “v3Lat”, “v3Lng”.
  /// 
  factory Incidencia.fromMap(Map<String, dynamic> map, String docId) {
    final tipoString = map['tipo'] as String? ?? 'calle_cortada';
    final tipoEnum = tipoFromString(tipoString);

    final titulo      = map['titulo'] as String? ?? '';
    final descripcion = map['descripcion'] as String? ?? '';
    final fechaStr    = map['fecha'] as String? ?? '';
    final fecha       = DateTime.tryParse(fechaStr) ?? DateTime.now();
    final userId      = map['userId'] as String? ?? '';

    switch (tipoEnum) {
      case TipoIncidencia.calle_cortada:
        final double iLat = (map['inicioLat'] as num?)?.toDouble() ?? 0.0;
        final double iLng = (map['inicioLng'] as num?)?.toDouble() ?? 0.0;
        final double fLat = (map['finLat'   ] as num?)?.toDouble() ?? 0.0;
        final double fLng = (map['finLng'   ] as num?)?.toDouble() ?? 0.0;
        return Incidencia(
          id: docId,
          tipo: tipoEnum,
          titulo: titulo,
          descripcion: descripcion,
          fecha: fecha,
          userId: userId,
          inicio: LatLng(iLat, iLng),
          fin:    LatLng(fLat, fLng),
        );

      case TipoIncidencia.zona_terremoto:
        final double cLat = (map['centroLat'] as num?)?.toDouble() ?? 0.0;
        final double cLng = (map['centroLng'] as num?)?.toDouble() ?? 0.0;
        final double radioValor = (map['radio'] as num?)?.toDouble() ?? 0.0;
        return Incidencia(
          id: docId,
          tipo: tipoEnum,
          titulo: titulo,
          descripcion: descripcion,
          fecha: fecha,
          userId: userId,
          centro: LatLng(cLat, cLng),
          radio: radioValor,
        );

      case TipoIncidencia.inundacion:
        // Se esperan cuatro pares: v0Lat/v0Lng … v3Lat/v3Lng
        List<LatLng> lista = [];
        for (int i = 0; i < 4; i++) {
          final double vLat = (map['v${i}Lat'] as num?)?.toDouble() ?? 0.0;
          final double vLng = (map['v${i}Lng'] as num?)?.toDouble() ?? 0.0;
          lista.add(LatLng(vLat, vLng));
        }
        return Incidencia(
          id: docId,
          tipo: tipoEnum,
          titulo: titulo,
          descripcion: descripcion,
          fecha: fecha,
          userId: userId,
          vertices: lista,
        );
    }
  }

  /// Convierte la instancia a Map para persistir (por ejemplo, en Firestore o en otro servicio).
  /// Incluye sólo los campos relevantes según [tipo].
  Map<String, dynamic> toMap() {
    final base = <String, dynamic>{
      'tipo': tipoToString(tipo),
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
      'userId': userId,
    };

    switch (tipo) {
      case TipoIncidencia.calle_cortada:
        base['inicioLat'] = inicio!.latitude;
        base['inicioLng'] = inicio!.longitude;
        base['finLat']    = fin!.latitude;
        base['finLng']    = fin!.longitude;
        break;

      case TipoIncidencia.zona_terremoto:
        base['centroLat'] = centro!.latitude;
        base['centroLng'] = centro!.longitude;
        base['radio']     = radio!;
        break;

      case TipoIncidencia.inundacion:
        for (int i = 0; i < 4; i++) {
          base['v${i}Lat'] = vertices![i].latitude;
          base['v${i}Lng'] = vertices![i].longitude;
        }
        break;
    }

    return base;
  }
}
