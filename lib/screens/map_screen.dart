// lib/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/incidencia.dart';
import '../models/punto_ayuda.dart';
import '../services/alertas_service.dart';
import '../services/sesion.dart';
import '../services/ubicacion_service.dart';
import '../utils/formato.dart';
import '../widgets/mapa_base.dart';

/// Permite que otras pantallas muevan el mapa (p. ej. "Ver en el mapa").
class FocoMapa extends ChangeNotifier {
  LatLng? _destino;
  double _zoom = 16;

  /// Centro visible del mapa, actualizado al moverlo.
  LatLng? centroVisible;

  void enfocar(LatLng punto, {double zoom = 16}) {
    _destino = punto;
    _zoom = zoom;
    notifyListeners();
  }
}

/// Pestaña del mapa: incidencias, puntos de ayuda, tu ubicación y el radio
/// de alerta.
class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.incidencias,
    required this.puntosAyuda,
    required this.foco,
    required this.onTapIncidencia,
    required this.onTapPuntoAyuda,
    required this.onLongPress,
  });

  final List<Incidencia> incidencias;
  final List<PuntoAyuda> puntosAyuda;
  final FocoMapa foco;
  final void Function(Incidencia) onTapIncidencia;
  final void Function(PuntoAyuda) onTapPuntoAyuda;
  final void Function(LatLng) onLongPress;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final _ubicacion = UbicacionService.instance;
  final _alertas = AlertasService.instance;

  bool _mapaListo = false;
  bool _usuarioMovioMapa = false;
  bool _centradoEnUsuario = false;
  bool _verIncidencias = true;
  bool _verAyuda = true;

  @override
  void initState() {
    super.initState();
    widget.foco.addListener(_aplicarFoco);
    _ubicacion.addListener(_centrarEnUsuarioSiProcede);
  }

  @override
  void dispose() {
    widget.foco.removeListener(_aplicarFoco);
    _ubicacion.removeListener(_centrarEnUsuarioSiProcede);
    _mapController.dispose();
    super.dispose();
  }

  void _onMapReady() {
    _mapaListo = true;
    _centrarEnUsuarioSiProcede();
    _aplicarFoco();
  }

  /// La primera vez que conocemos la ubicación, centramos el mapa en ella
  /// (salvo que el usuario ya lo haya movido).
  void _centrarEnUsuarioSiProcede() {
    final pos = _ubicacion.posicion;
    if (!_mapaListo || _centradoEnUsuario || _usuarioMovioMapa || pos == null) return;
    _centradoEnUsuario = true;
    _mapController.move(pos, 15);
  }

  void _aplicarFoco() {
    final destino = widget.foco._destino;
    if (!_mapaListo || destino == null) return;
    widget.foco._destino = null;
    _usuarioMovioMapa = true;
    setState(() => _verIncidencias = _verAyuda = true);
    _mapController.move(destino, widget.foco._zoom);
  }

  void _zoom(double delta) {
    final camara = _mapController.camera;
    _mapController.move(camara.center, (camara.zoom + delta).clamp(3, 19));
  }

  void _irAMiUbicacion() {
    final pos = _ubicacion.posicion;
    if (pos == null) {
      _ubicacion.iniciar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ubicacion.error ?? 'Buscando tu ubicación…')),
      );
      return;
    }
    _mapController.move(pos, 16);
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([_ubicacion, _alertas]),
      builder: (context, _) {
        final pos = _ubicacion.posicion;
        final activas = widget.incidencias.where((i) => i.activa).toList();

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _ubicacion.posicionOPorDefecto,
                initialZoom: 14,
                minZoom: 3,
                maxZoom: 19,
                onMapReady: _onMapReady,
                onLongPress: (_, punto) => widget.onLongPress(punto),
                onPositionChanged: (camara, conGesto) {
                  widget.foco.centroVisible = camara.center;
                  if (conGesto) _usuarioMovioMapa = true;
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                // 1) Capa base (OpenStreetMap)
                capaOpenStreetMap(),

                // 2) Radio de alerta alrededor del usuario
                if (pos != null && _alertas.activadas)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: pos,
                        radius: _alertas.radioMetros,
                        useRadiusInMeter: true,
                        color: colores.primary.withValues(alpha: 0.06),
                        borderColor: colores.primary.withValues(alpha: 0.5),
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),

                // 3) Zonas afectadas (polígonos, círculos y líneas)
                if (_verIncidencias) ...capasZonasIncidencias(activas),

                // 4) Puntos de ayuda e iconos de incidencias
                if (_verAyuda)
                  capaMarcadoresAyuda(widget.puntosAyuda, onTap: widget.onTapPuntoAyuda),
                if (_verIncidencias)
                  capaMarcadoresIncidencias(activas, onTap: widget.onTapIncidencia),

                // 5) Ubicación del usuario
                if (pos != null)
                  MarkerLayer(markers: [marcadorUsuario(pos, simulada: _ubicacion.esSimulada)]),

                atribucionOpenStreetMap(),
              ],
            ),

            // Avisos y filtros en la parte superior
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_alertas.cercanas.isNotEmpty)
                    _BannerCercanas(
                      cercanas: _alertas.cercanas,
                      onTap: () {
                        final inc = _alertas.cercanas.first.incidencia;
                        _usuarioMovioMapa = true;
                        _mapController.move(inc.posicion, 16);
                        widget.onTapIncidencia(inc);
                      },
                    ),
                  if (_ubicacion.error != null && !_ubicacion.esSimulada)
                    _AvisoUbicacion(
                      mensaje: _ubicacion.error!,
                      demo: Sesion.instance.esDemo,
                      onReintentar: _ubicacion.iniciar,
                    ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        avatar: const Icon(Icons.warning_amber, size: 18),
                        label: Text('Incidencias (${activas.length})'),
                        selected: _verIncidencias,
                        onSelected: (v) => setState(() => _verIncidencias = v),
                      ),
                      FilterChip(
                        avatar: const Icon(Icons.volunteer_activism, size: 18),
                        label: Text('Ayuda (${widget.puntosAyuda.length})'),
                        selected: _verAyuda,
                        onSelected: (v) => setState(() => _verAyuda = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Controles flotantes: zoom y mi ubicación
            Positioned(
              right: 16,
              bottom: 96,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BotonMapa(icono: Icons.add, tooltip: 'Acercar', onPressed: () => _zoom(1)),
                  const SizedBox(height: 8),
                  _BotonMapa(icono: Icons.remove, tooltip: 'Alejar', onPressed: () => _zoom(-1)),
                  const SizedBox(height: 16),
                  _BotonMapa(
                    icono: _ubicacion.cargando ? Icons.location_searching : Icons.my_location,
                    tooltip: 'Mi ubicación',
                    onPressed: _irAMiUbicacion,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BotonMapa extends StatelessWidget {
  const _BotonMapa({required this.icono, required this.tooltip, required this.onPressed});

  final IconData icono;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Material(
      color: colores.surface,
      elevation: 3,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icono, color: colores.onSurface),
      ),
    );
  }
}

/// Aviso rojo cuando hay incidencias dentro del radio de alerta.
class _BannerCercanas extends StatelessWidget {
  const _BannerCercanas({required this.cercanas, required this.onTap});

  final List<IncidenciaCercana> cercanas;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final primera = cercanas.first;
    final dentro = cercanas.any((c) => c.dentro);
    final titulo = dentro
        ? 'Estás dentro de una zona afectada'
        : cercanas.length == 1
            ? 'Incidencia a ${formatearDistancia(primera.distancia)}'
            : '${cercanas.length} incidencias cerca de ti';

    return Card(
      color: colores.errorContainer,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.warning_amber_rounded, color: colores.onErrorContainer, size: 32),
        title: Text(
          titulo,
          style: TextStyle(color: colores.onErrorContainer, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          primera.incidencia.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: colores.onErrorContainer),
        ),
        trailing: Icon(Icons.chevron_right, color: colores.onErrorContainer),
      ),
    );
  }
}

class _AvisoUbicacion extends StatelessWidget {
  const _AvisoUbicacion({required this.mensaje, required this.demo, required this.onReintentar});

  final String mensaje;
  final bool demo;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            const Icon(Icons.location_off),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                demo ? '$mensaje\nModo demo: mantén pulsado el mapa para simular tu ubicación.' : mensaje,
              ),
            ),
            TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
