import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialCenter = LatLng(40.4168, -3.7038);

  @override
  Widget build(BuildContext context) {
    const buttonSize = 48.0;
    const spacing   = 12.0;
    final white     = Colors.white;
    final highlight = Colors.grey.withOpacity(0.2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(center: _initialCenter, zoom: 13.0),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.crisis_map_natural',
              ),
            ],
          ),

          Positioned(
            right: 16,
            bottom: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Zoom In
                Material(
                  color: white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    highlightColor: highlight,
                    onTap: () {
                      final zoom = _mapController.zoom;
                      _mapController.move(_mapController.center, zoom + 1);
                    },
                    child: SizedBox(
                      width: buttonSize,
                      height: buttonSize,
                      child: const Icon(Icons.zoom_in, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: spacing),

                // Zoom Out
                Material(
                  color: white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    highlightColor: highlight,
                    onTap: () {
                      final zoom = _mapController.zoom;
                      _mapController.move(_mapController.center, zoom - 1);
                    },
                    child: SizedBox(
                      width: buttonSize,
                      height: buttonSize,
                      child: const Icon(Icons.zoom_out, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: spacing),

                // Botón 3 placeholder
                Material(
                  color: white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    highlightColor: highlight,
                    onTap: () {
                      Navigator.pushNamed(context, '/filters');
                    },
                    child: SizedBox(
                      width: buttonSize,
                      height: buttonSize,
                      child: const Icon(Icons.more_horiz, color: Colors.black),
                    ),
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
