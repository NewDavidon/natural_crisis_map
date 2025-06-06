// lib/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/incidencia.dart';
import '../models/tipo_incidencia.dart';
import '../services/pending_incidents_service.dart';
import 'incidencia_form_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  bool _loadingLocation = true;
  String? _locError;
  LatLng? _currentCenter;
  LatLng? _selectedPosition;
  List<Incidencia> _pendingIncidents = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _loadPendingIncidents();
  }

  /// Obtiene la posición actual con Geolocator y la guarda en `_currentCenter`.
  Future<void> _determinePosition() async {
    setState(() => _loadingLocation = true);

    try {
      // 1) Verificar si el servicio de ubicación está habilitado
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Servicios de ubicación deshabilitados';
      }

      // 2) Verificar/solicitar permisos
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          throw 'Permiso de ubicación denegado';
        }
      }
      if (perm == LocationPermission.deniedForever) {
        throw 'Permiso de ubicación denegado permanentemente';
      }

      // 3) Intentar obtener la posición con timeout
      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        // Si falla, fallback a última posición conocida o a Madrid
        pos = await Geolocator.getLastKnownPosition() ??
            Position(
              latitude: 40.4168,
              longitude: -3.7038,
              timestamp: DateTime.now(),
              accuracy: 0.0,
              altitude: 0.0,
              heading: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0,
            );
      }

      _currentCenter = LatLng(pos.latitude, pos.longitude);
      _locError = null;

      // Una vez obtenida la coordenada, movemos el mapa
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentCenter != null) {
          _mapController.move(_currentCenter!, 13.0);
        }
      });
    } catch (e) {
      _locError = e.toString();
      // Si hubo error, centramos en Madrid por defecto
      _currentCenter = LatLng(40.4168, -3.7038);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_currentCenter!, 5.0);
      });
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  /// Carga la lista de incidencias pendientes
  void _loadPendingIncidents() {
    setState(() {
      _pendingIncidents = PendingIncidentsService.instance.all;
    });
  }

  void _refreshAll() {
    _loadPendingIncidents();
  }

  /// Construye las capas de incidencias: polilíneas, círculos y polígonos
  List<Widget> _buildPendingLayers() {
    final List<Widget> hijos = [];

    for (var inc in _pendingIncidents) {
      switch (inc.tipo) {
        case TipoIncidencia.calle_cortada:
          final inicio = inc.inicio!;
          final fin = inc.fin!;
          hijos.add(
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [
                    LatLng(inicio.latitude, inicio.longitude),
                    LatLng(fin.latitude, fin.longitude),
                  ],
                  strokeWidth: 4,
                  color: Colors.red,
                ),
              ],
            ),
          );
          break;

        case TipoIncidencia.zona_terremoto:
          hijos.add(
            CircleLayer(
              circles: [
                CircleMarker(
                  point: inc.centro!,
                  color: Colors.orange.withOpacity(0.3),
                  borderColor: Colors.orange,
                  borderStrokeWidth: 2,
                  radius: inc.radio!, // en metros
                ),
              ],
            ),
          );
          break;

        case TipoIncidencia.inundacion:
          hijos.add(
            PolygonLayer(
              polygons: [
                Polygon(
                  points: inc.vertices!,
                  color: Colors.blue.withOpacity(0.3),
                  borderColor: Colors.blue,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
          );
          break;
      }
    }

    return hijos;
  }

  @override
  Widget build(BuildContext context) {
    const double buttonSize = 48.0;
    const double spacing = 12.0;
    final Color blanco = Colors.white;
    final Color highlight = Colors.grey.withOpacity(0.2);

    if (_loadingLocation) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar borradores',
            onPressed: _refreshAll,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentCenter,
              zoom: 13.0,
              onTap: (tapPos, latlng) {
                setState(() {
                  _selectedPosition = latlng;
                });
              },
            ),
            children: [
              // 1) Capa base (OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.crisis_map_natural',
              ),

              // 2) Marcador de ubicación actual (un punto azul)
              if (_currentCenter != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentCenter!,
                      width: 40,
                      height: 40,
                      builder: (ctx) => const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                  ],
                ),

              // 3) Capas de incidencias pendientes (polyline, circle, polygon)
              ..._buildPendingLayers(),
            ],
          ),

          // Si hay error de ubicación, muestra un banner rojo
          if (_locError != null)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withOpacity(0.8),
                child: Text(
                  _locError!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )

          // Si no hay error y no se ha pulsado el mapa, muestra instrucción
          else if (_selectedPosition == null)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white.withOpacity(0.8),
                child: const Text(
                  'Toca en el mapa para elegir ubicación',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            )

          // Si se toca en el mapa, muestra las coordenadas seleccionadas
          else
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white.withOpacity(0.8),
                child: Text(
                  'Ubicación seleccionada: '
                  'Lat ${_selectedPosition!.latitude.toStringAsFixed(5)}, '
                  'Lng ${_selectedPosition!.longitude.toStringAsFixed(5)}',
                ),
              ),
            ),

          // Controles flotantes de zoom
          Positioned(
            right: 16,
            bottom: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: blanco,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    highlightColor: highlight,
                    onTap: () => _mapController.move(
                      _mapController.center,
                      _mapController.zoom + 1,
                    ),
                    child: SizedBox(
                      width: buttonSize,
                      height: buttonSize,
                      child: const Icon(Icons.zoom_in, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: spacing),
                Material(
                  color: blanco,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    highlightColor: highlight,
                    onTap: () => _mapController.move(
                      _mapController.center,
                      _mapController.zoom - 1,
                    ),
                    child: SizedBox(
                      width: buttonSize,
                      height: buttonSize,
                      child: const Icon(Icons.zoom_out, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Botón flotante para "Nueva incidencia"
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/nuevo-informe')
              .then((_) => _refreshAll());
        },
        child: const Icon(Icons.add),
        tooltip: 'Nueva incidencia',
      ),
    );
  }
}
