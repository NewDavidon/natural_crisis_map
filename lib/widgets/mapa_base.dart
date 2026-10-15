import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/incidencia.dart';
import '../models/punto_ayuda.dart';
import '../models/tipo_incidencia.dart';

/// Capa de teselas de OpenStreetMap que comparten todos los mapas.
TileLayer capaOpenStreetMap() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.crisis_map_natural',
    );

/// Atribución obligatoria de OpenStreetMap.
Widget atribucionOpenStreetMap() => const SimpleAttributionWidget(
      source: Text('OpenStreetMap contributors'),
    );

/// Marcador redondo con un icono, usado para incidencias y puntos de ayuda.
class IconoMapa extends StatelessWidget {
  const IconoMapa({
    super.key,
    required this.icono,
    required this.color,
    this.tamano = 36,
    this.onTap,
    this.atenuado = false,
  });

  final IconData icono;
  final Color color;
  final double tamano;
  final VoidCallback? onTap;
  final bool atenuado;

  @override
  Widget build(BuildContext context) {
    final fondo = atenuado ? Colors.grey : color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(
          color: fondo,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Icon(icono, color: Colors.white, size: tamano * 0.55),
      ),
    );
  }
}

/// Dibuja la zona afectada de cada incidencia (línea, círculo o polígono).
List<Widget> capasZonasIncidencias(List<Incidencia> incidencias) {
  final lineas = <Polyline>[];
  final circulos = <CircleMarker>[];
  final poligonos = <Polygon>[];

  for (final inc in incidencias) {
    final color = inc.tipo.color;
    switch (inc.tipo.geometria) {
      case GeometriaZona.linea:
        lineas.add(Polyline(
          points: [inc.inicio!, inc.fin!],
          strokeWidth: 6,
          color: color,
          borderStrokeWidth: 2,
          borderColor: Colors.white,
        ));
      case GeometriaZona.circulo:
        circulos.add(CircleMarker(
          point: inc.centro!,
          radius: inc.radio!,
          useRadiusInMeter: true,
          color: color.withValues(alpha: 0.25),
          borderColor: color,
          borderStrokeWidth: 2,
        ));
      case GeometriaZona.poligono:
        poligonos.add(Polygon(
          points: inc.vertices!,
          color: color.withValues(alpha: 0.25),
          borderColor: color,
          borderStrokeWidth: 2,
        ));
    }
  }

  return [
    if (poligonos.isNotEmpty) PolygonLayer(polygons: poligonos),
    if (circulos.isNotEmpty) CircleLayer(circles: circulos),
    if (lineas.isNotEmpty) PolylineLayer(polylines: lineas),
  ];
}

/// Marcadores con icono para incidencias y puntos de ayuda.
MarkerLayer capaMarcadoresIncidencias(
  List<Incidencia> incidencias, {
  required void Function(Incidencia) onTap,
}) {
  return MarkerLayer(
    markers: [
      for (final inc in incidencias)
        Marker(
          point: inc.posicion,
          width: 40,
          height: 40,
          child: IconoMapa(
            icono: inc.tipo.icono,
            color: inc.tipo.color,
            tamano: 40,
            onTap: () => onTap(inc),
          ),
        ),
    ],
  );
}

MarkerLayer capaMarcadoresAyuda(
  List<PuntoAyuda> puntos, {
  required void Function(PuntoAyuda) onTap,
}) {
  return MarkerLayer(
    markers: [
      for (final p in puntos)
        Marker(
          point: p.posicion,
          width: 32,
          height: 32,
          child: IconoMapa(
            icono: p.tipo.icono,
            color: p.tipo.color,
            tamano: 32,
            onTap: () => onTap(p),
          ),
        ),
    ],
  );
}

/// Punto azul con halo para la ubicación del usuario.
Marker marcadorUsuario(LatLng posicion, {bool simulada = false}) {
  final color = simulada ? Colors.deepPurple : Colors.blue;
  return Marker(
    point: posicion,
    width: 28,
    height: 28,
    child: Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
        ),
      ),
    ),
  );
}
