// lib/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

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

  /// Marcador que el usuario añade con un tap
  LatLng? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() => _loadingLocation = true);

    try {
      // 1) Verificar servicio GPS
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Servicios de ubicación deshabilitados';
      }

      // 2) Solicitar permiso
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          throw 'Permiso de ubicación denegado';
        }
      }
      if (perm == LocationPermission.deniedForever) {
        throw 'Permiso denegado permanentemente';
      }

      // 3) Intentar obtener posición con timeout
      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Fallback a última conocida o Madrid
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

      // Esperar al primer frame para mover el mapa, evitando el LateInitializationError
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_currentCenter!, 13.0);
      });
    } catch (e) {
      _locError = e.toString();
      _currentCenter = LatLng(40.4168, -3.7038);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_currentCenter!, 5.0);
      });
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double buttonSize = 48.0;
    const double spacing = 12.0;
    final Color white = Colors.white;
    final Color highlight = Colors.grey.withOpacity(0.2);

    if (_loadingLocation) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa'), centerTitle: true),
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
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.crisis_map_natural',
              ),
              MarkerLayer(
                markers: [
                  if (_currentCenter != null)
                    Marker(
                      point: _currentCenter!,
                      width: 30,
                      height: 30,
                      builder: (_) => const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                  if (_selectedPosition != null)
                    Marker(
                      point: _selectedPosition!,
                      width: 30,
                      height: 30,
                      builder: (_) => const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Banner superior con error o coordenadas
          if (_locError != null)
            Positioned(
              top: 8, left: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withOpacity(0.8),
                child: Text(
                  _locError!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
          else if (_selectedPosition != null)
            Positioned(
              top: 8, left: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white.withOpacity(0.8),
                child: Text(
                  'Seleccionado: '
                  'Lat ${_selectedPosition!.latitude.toStringAsFixed(5)}, '
                  'Lng ${_selectedPosition!.longitude.toStringAsFixed(5)}',
                ),
              ),
            ),

          // Controles flotantes
          Positioned(
            right: 16, bottom: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: white,
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
                  color: white,
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
                const SizedBox(height: spacing),
                Material(
                  color: white,
                  shape: const CircleBorder(),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: Colors.black),
                    onSelected: (value) {
                      if (value == 'add') {
                        Navigator.pushNamed(
                          context,
                          '/rellenar-incidencias',
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'add',
                        child: Text('Rellenar incidencia'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
