// lib/screens/map_zona_terremoto_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/tipo_incidencia.dart';
import '../services/pending_incidents_service.dart';

class MapZonaTerremotoScreen extends StatefulWidget {
  final String titulo;
  final String descripcion;

  const MapZonaTerremotoScreen({
    Key? key,
    required this.titulo,
    required this.descripcion,
  }) : super(key: key);

  @override
  State<MapZonaTerremotoScreen> createState() => _MapZonaTerremotoScreenState();
}

class _MapZonaTerremotoScreenState extends State<MapZonaTerremotoScreen> {
  final MapController _mapController = MapController();

  LatLng? _centro;
  LatLng? _puntoPerimetro; // para calcular radio
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
      if (_centro == null) {
        _centro = latlng;
      } else if (_puntoPerimetro == null) {
        _puntoPerimetro = latlng;
      } else {
        // Reiniciamos el flujo: el nuevo tap será el nuevo centro
        _centro = latlng;
        _puntoPerimetro = null;
      }
    });
  }

  double _calcularRadio() {
    if (_centro == null || _puntoPerimetro == null) return 0.0;
    final dist = Distance().distance(_centro!, _puntoPerimetro!);
    return dist; // en metros
  }

  void _guardarIncidencia() {
    if (_centro == null || _puntoPerimetro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marca un centro y un punto de perímetro')),
      );
      return;
    }
    final radio = _calcularRadio();

    PendingIncidentsService.instance.add(
      tipo: TipoIncidencia.zona_terremoto,
      titulo: widget.titulo,
      descripcion: widget.descripcion,
      centro: _centro!,
      radio: radio,
      fecha: DateTime.now(),
      userId: 'pending',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Incidencia zona terremoto guardada'),
        action: SnackBarAction(
          label: 'VOLVER',
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double radio = _calcularRadio();

    return Scaffold(
      appBar: AppBar(title: const Text('Definir zona terremoto')),
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
              if (_centro != null && radio > 0)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _centro!,
                      color: Colors.red.withOpacity(0.3),
                      borderStrokeWidth: 2,
                      borderColor: Colors.red,
                      radius: radio, // en metros
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_centro != null)
                    Marker(
                      point: _centro!,
                      width: 30,
                      height: 30,
                      builder: (_) => const Icon(Icons.adjust, color: Colors.red, size: 30),
                    ),
                  if (_puntoPerimetro != null)
                    Marker(
                      point: _puntoPerimetro!,
                      width: 30,
                      height: 30,
                      builder: (_) => const Icon(Icons.place, color: Colors.orange, size: 30),
                    ),
                ],
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

          // Indicador superior
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white.withOpacity(0.8),
              child: Text(
                _centro == null
                    ? 'Toca para marcar centro'
                    : (_puntoPerimetro == null
                        ? 'Toca para marcar perímetro'
                        : 'Radio ≈ ${radio.toStringAsFixed(1)} m'),
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
