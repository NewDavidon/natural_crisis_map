// lib/screens/map_calle_cortada_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/tipo_incidencia.dart';
import '../services/pending_incidents_service.dart';

/// Pantalla para que el usuario defina una “calle cortada” marcando
/// un punto de inicio y un punto de fin en el mapa. Recibe el título
/// y descripción de la incidencia desde la pantalla anterior.
class MapCalleCortadaScreen extends StatefulWidget {
  final String titulo;
  final String descripcion;

  const MapCalleCortadaScreen({
    Key? key,
    required this.titulo,
    required this.descripcion,
  }) : super(key: key);

  @override
  State<MapCalleCortadaScreen> createState() => _MapCalleCortadaScreenState();
}

class _MapCalleCortadaScreenState extends State<MapCalleCortadaScreen> {
  late final MapController _mapController;

  /// Puntos que define el usuario (inicio y fin de la calle cortada).
  LatLng? _puntoInicio;
  LatLng? _puntoFin;

  /// Indica si el mapa aún está “cargando” antes de mostrar la UI completa.
  bool _loadingLocation = true;

  /// Centro por defecto: Madrid.
  final LatLng _centerDefault = LatLng(40.4168, -3.7038);
  final double _startZoom = 13.0;

  @override
  void initState() {
    super.initState();

    // 1) Inicializar MapController.
    _mapController = MapController();

    // 2) Hacemos un pequeño delay para centrar la cámara y luego quitar el spinner.
    Future.delayed(const Duration(milliseconds: 300), () {
      _mapController.move(_centerDefault, _startZoom);
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    });
  }

  /// Se invoca al tocar el mapa:
  /// - Primero asigna `_puntoInicio`,
  /// - Luego asigna `_puntoFin`,
  /// - Si ambos existen, reinicia el flujo (nuevo inicio).
  void _onTapMapa(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      if (_puntoInicio == null) {
        _puntoInicio = latlng;
      } else if (_puntoFin == null) {
        _puntoFin = latlng;
      } else {
        // Reiniciar: el tap actual será nuevo puntoInicio
        _puntoInicio = latlng;
        _puntoFin = null;
      }
    });
  }

  /// Valida que existan ambos puntos, crea la incidencia en memoria y muestra Snackbar.
  void _guardarIncidencia() {
    if (_puntoInicio == null || _puntoFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marca un punto de inicio y uno de fin')),
      );
      return;
    }

    // Llamada al servicio (PendingIncidentsService) con tipo calle_cortada,
    // pasando los LatLng de inicio y fin.
    PendingIncidentsService.instance.add(
      tipo: TipoIncidencia.calle_cortada,
      titulo: widget.titulo,
      descripcion: widget.descripcion,
      inicio: _puntoInicio!,
      fin: _puntoFin!,
      fecha: DateTime.now(),
      userId: 'pending',
    );

    // Mostrar Snackbar de éxito con botón “VOLVER” que regresa a la raíz.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Incidencia de calle cortada guardada'),
        action: SnackBarAction(
          label: 'VOLVER',
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Definir calle cortada'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // FlutterMap con su MapController
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _centerDefault,
              zoom: _startZoom,
              onTap: _onTapMapa,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.crisis_map_natural',
              ),
              MarkerLayer(
                markers: [
                  if (_puntoInicio != null)
                    Marker(
                      point: _puntoInicio!,
                      width: 30,
                      height: 30,
                      builder: (_) => const Icon(
                        Icons.place,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  if (_puntoFin != null)
                    Marker(
                      point: _puntoFin!,
                      width: 30,
                      height: 30,
                      builder: (_) => const Icon(
                        Icons.place,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Overlay con spinner mientras _loadingLocation == true
          if (_loadingLocation)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.white70,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          // Indicador textual en la parte superior (Stack).
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white.withOpacity(0.8),
              child: Text(
                _puntoInicio == null
                    ? 'Toca para marcar inicio'
                    : (_puntoFin == null
                        ? 'Toca para marcar fin'
                        : 'Listo para guardar'),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),

      // Botón flotante “Guardar”
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardarIncidencia,
        icon: const Icon(Icons.check),
        label: const Text('Guardar'),
      ),
    );
  }
}
