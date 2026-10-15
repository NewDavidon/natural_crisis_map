import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/incidencia.dart';
import '../models/tipo_incidencia.dart';

const _distancia = Distance(roundResult: false);

/// Distancia en metros entre dos coordenadas.
double distanciaMetros(LatLng a, LatLng b) => _distancia.as(LengthUnit.Meter, a, b);

/// Proyecta [p] a un plano local en metros centrado en [origen].
/// Es suficientemente preciso para distancias de pocos kilómetros.
math.Point<double> _proyectar(LatLng p, LatLng origen) {
  // Longitud de un grado según la latitud (aproximación del elipsoide WGS84).
  final lat = origen.latitude * math.pi / 180;
  final metrosPorGradoLat = 111132.92 - 559.82 * math.cos(2 * lat) + 1.175 * math.cos(4 * lat);
  final metrosPorGradoLng = 111412.84 * math.cos(lat) - 93.5 * math.cos(3 * lat);
  return math.Point(
    (p.longitude - origen.longitude) * metrosPorGradoLng,
    (p.latitude - origen.latitude) * metrosPorGradoLat,
  );
}

/// Distancia en metros desde [p] al segmento [a]–[b].
double distanciaASegmento(LatLng p, LatLng a, LatLng b) {
  // Trabajamos en un plano con [p] en el origen.
  final pa = _proyectar(a, p);
  final pb = _proyectar(b, p);
  final dx = pb.x - pa.x;
  final dy = pb.y - pa.y;
  final longitud2 = dx * dx + dy * dy;
  var t = longitud2 == 0 ? 0.0 : -(pa.x * dx + pa.y * dy) / longitud2;
  t = t.clamp(0.0, 1.0);
  final cx = pa.x + t * dx;
  final cy = pa.y + t * dy;
  return math.sqrt(cx * cx + cy * cy);
}

/// Indica si [p] está dentro del polígono definido por [vertices]
/// (algoritmo de ray casting).
bool puntoEnPoligono(LatLng p, List<LatLng> vertices) {
  var dentro = false;
  for (var i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
    final vi = vertices[i];
    final vj = vertices[j];
    final cruza = (vi.latitude > p.latitude) != (vj.latitude > p.latitude) &&
        p.longitude <
            (vj.longitude - vi.longitude) * (p.latitude - vi.latitude) /
                    (vj.latitude - vi.latitude) +
                vi.longitude;
    if (cruza) dentro = !dentro;
  }
  return dentro;
}

/// Distancia en metros desde [p] hasta la zona afectada por [inc].
/// Devuelve 0 si el punto está dentro de la zona.
double distanciaAIncidencia(LatLng p, Incidencia inc) {
  switch (inc.tipo.geometria) {
    case GeometriaZona.linea:
      return distanciaASegmento(p, inc.inicio!, inc.fin!);
    case GeometriaZona.circulo:
      return math.max(0, distanciaMetros(p, inc.centro!) - inc.radio!);
    case GeometriaZona.poligono:
      final vs = inc.vertices!;
      if (puntoEnPoligono(p, vs)) return 0;
      var minima = double.infinity;
      for (var i = 0; i < vs.length; i++) {
        final d = distanciaASegmento(p, vs[i], vs[(i + 1) % vs.length]);
        if (d < minima) minima = d;
      }
      return minima;
  }
}
