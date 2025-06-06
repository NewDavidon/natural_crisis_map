// lib/screens/map_inundacion_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/tipo_incidencia.dart';
import '../services/pending_incidents_service.dart';

class MapInundacionScreen extends StatefulWidget {
  final String titulo;
  final String descripcion;

  const MapInundacionScreen({
    Key? key,
    required this.titulo,
    required this.descripcion,
  }) : super(key: key);

  @override
  State<MapInundacionScreen> createState() => _MapInundacionScreenState();
}

class _MapInundacionScreenState extends State<MapInundacionScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _vertices = [];
  bool _loadingLocation = true;
  final LatLng _centerDefault = LatLng(40.4168, -3.7038);

  @override
  void initState() {
    super.initState();
    // Simular retardo corto para centrar la cámara y quitar el spinner
    Future.delayed(const Duration(milliseconds: 300), () {
      _mapController.move(_centerDefault, 13.0);
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    });
  }

  void _onTapMapa(TapPosition tapPos, LatLng latlng) {
    setState(() {
      if (_vertices.length < 4) {
        _vertices.add(latlng);
      } else {
        // Si ya hay 4 vértices, reiniciamos y agregamos el nuevo como primer vértice
        _vertices = [latlng];
      }
    });
  }

  void _guardarIncidencia() {
    if (_vertices.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marca exactamente 4 vértices')),
      );
      return;
    }

    PendingIncidentsService.instance.add(
      tipo: TipoIncidencia.inundacion,
      titulo: widget.titulo,
      descripcion: widget.descripcion,
      vertices: _vertices,
      fecha: DateTime.now(),
      userId: 'pending',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Incidencia inundación guardada'),
        action: SnackBarAction(
          label: 'VOLVER',
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Definir inundación')),
      body: Stack(
        children: [
          // Mapa siempre presente
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _centerDefault,
              zoom: 13.0,
              onTap: _onTapMapa,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.crisis_map_natural',
              ),
              if (_vertices.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _vertices,
                      color: Colors.blue.withOpacity(0.3),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: _vertices.map((p) {
                  return Marker(
                    point: p,
                    width: 25,
                    height: 25,
                    builder: (_) => const Icon(Icons.circle, color: Colors.blue, size: 20),
                  );
                }).toList(),
              ),
            ],
          ),

          // Overlay con spinner mientras se inicializa el mapa
          if (_loadingLocation)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.white70,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          // Indicador superior: cuántos vértices se han marcado
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white.withOpacity(0.8),
              child: Text(
                _vertices.length < 4
                    ? 'Vértices marcados: ${_vertices.length} / 4'
                    : 'Listo para guardar',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardarIncidencia,
        icon: const Icon(Icons.check),
        label: const Text('Guardar'),
      ),
    );
  }
}
