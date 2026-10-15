import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/foto_incidencia.dart';
import '../models/incidencia.dart';
import '../models/tipo_incidencia.dart';
import '../services/sesion.dart';
import '../services/ubicacion_service.dart';
import '../utils/formato.dart';
import '../utils/geo.dart';
import '../widgets/mapa_base.dart';
import 'incidencia_form_screen.dart';

/// Paso 2 de 2 para reportar una incidencia: marcar la zona afectada.
///
/// Según el tipo se dibuja una línea (inicio y fin), un círculo (centro y
/// radio) o un polígono (3 o más vértices).
class DefinirZonaScreen extends StatefulWidget {
  const DefinirZonaScreen({super.key, required this.borrador});

  final BorradorIncidencia borrador;

  @override
  State<DefinirZonaScreen> createState() => _DefinirZonaScreenState();
}

class _DefinirZonaScreenState extends State<DefinirZonaScreen> {
  static const _radioMinimo = 50.0;
  static const _radioMaximo = 5000.0;

  final MapController _mapController = MapController();
  final _ubicacion = UbicacionService.instance;

  // Línea
  LatLng? _inicio;
  LatLng? _fin;
  // Círculo
  LatLng? _centro;
  double _radio = 300;
  // Polígono
  final List<LatLng> _vertices = [];

  bool _guardando = false;

  GeometriaZona get _geometria => widget.borrador.tipo.geometria;
  Color get _color => widget.borrador.tipo.color;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  bool get _completa => switch (_geometria) {
        GeometriaZona.linea => _inicio != null && _fin != null,
        GeometriaZona.circulo => _centro != null,
        GeometriaZona.poligono => _vertices.length >= 3,
      };

  String get _estado => switch (_geometria) {
        GeometriaZona.linea => _inicio == null
            ? 'Toca el mapa para marcar el INICIO del tramo'
            : _fin == null
                ? 'Ahora toca para marcar el FIN del tramo'
                : 'Tramo de ${formatearDistancia(distanciaMetros(_inicio!, _fin!))}. '
                    'Toca de nuevo para empezar otra vez.',
        GeometriaZona.circulo => _centro == null
            ? 'Toca el mapa para marcar el centro de la zona'
            : 'Radio afectado: ${formatearDistancia(_radio)}',
        GeometriaZona.poligono => _vertices.length < 3
            ? 'Puntos marcados: ${_vertices.length} (mínimo 3)'
            : 'Zona de ${_vertices.length} puntos. Puedes seguir añadiendo.',
      };

  void _onTapMapa(TapPosition _, LatLng punto) {
    if (_guardando) return;
    setState(() {
      switch (_geometria) {
        case GeometriaZona.linea:
          if (_inicio == null || _fin != null) {
            _inicio = punto;
            _fin = null;
          } else {
            _fin = punto;
          }
        case GeometriaZona.circulo:
          _centro = punto;
        case GeometriaZona.poligono:
          _vertices.add(punto);
      }
    });
  }

  void _deshacer() {
    setState(() {
      switch (_geometria) {
        case GeometriaZona.linea:
          if (_fin != null) {
            _fin = null;
          } else {
            _inicio = null;
          }
        case GeometriaZona.circulo:
          _centro = null;
        case GeometriaZona.poligono:
          if (_vertices.isNotEmpty) _vertices.removeLast();
      }
    });
  }

  bool get _hayAlgo => _inicio != null || _centro != null || _vertices.isNotEmpty;

  Future<void> _guardar() async {
    final usuario = Sesion.instance.usuario;
    if (!_completa || usuario == null) return;
    final b = widget.borrador;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _guardando = true);
    try {
      final ahora = DateTime.now();
      final incidencia = Incidencia(
        id: '',
        tipo: b.tipo,
        titulo: b.titulo,
        descripcion: b.descripcion,
        gravedad: b.gravedad,
        fecha: ahora,
        userId: usuario.uid,
        autor: usuario.nombre,
        inicio: _geometria == GeometriaZona.linea ? _inicio : null,
        fin: _geometria == GeometriaZona.linea ? _fin : null,
        centro: _geometria == GeometriaZona.circulo ? _centro : null,
        radio: _geometria == GeometriaZona.circulo ? _radio : null,
        vertices: _geometria == GeometriaZona.poligono ? List.of(_vertices) : null,
      );

      final repo = Sesion.instance.repo;
      final id = await repo.crearIncidencia(incidencia);
      for (final bytes in b.fotos) {
        await repo.anadirFoto(
          id,
          FotoIncidencia(id: '', bytes: bytes, fecha: ahora, userId: usuario.uid, autor: usuario.nombre),
        );
      }

      // Volvemos a la pantalla principal, que ya muestra la nueva incidencia.
      navigator.popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        const SnackBar(content: Text('Incidencia publicada. ¡Gracias por avisar!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      messenger.showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    }
  }

  List<Widget> _capasBorrador() {
    final relleno = _color.withValues(alpha: 0.3);
    return [
      if (_geometria == GeometriaZona.linea && _inicio != null && _fin != null)
        PolylineLayer(polylines: [
          Polyline(points: [_inicio!, _fin!], strokeWidth: 6, color: _color),
        ]),
      if (_geometria == GeometriaZona.circulo && _centro != null)
        CircleLayer(circles: [
          CircleMarker(
            point: _centro!,
            radius: _radio,
            useRadiusInMeter: true,
            color: relleno,
            borderColor: _color,
            borderStrokeWidth: 2,
          ),
        ]),
      if (_geometria == GeometriaZona.poligono && _vertices.length >= 2)
        PolygonLayer(polygons: [
          Polygon(points: _vertices, color: relleno, borderColor: _color, borderStrokeWidth: 2),
        ]),
      MarkerLayer(
        markers: [
          if (_inicio != null && _geometria == GeometriaZona.linea)
            _marcadorPunto(_inicio!, 'A'),
          if (_fin != null && _geometria == GeometriaZona.linea) _marcadorPunto(_fin!, 'B'),
          if (_centro != null && _geometria == GeometriaZona.circulo)
            Marker(
              point: _centro!,
              width: 36,
              height: 36,
              child: IconoMapa(icono: widget.borrador.tipo.icono, color: _color),
            ),
          if (_geometria == GeometriaZona.poligono)
            for (var i = 0; i < _vertices.length; i++) _marcadorPunto(_vertices[i], '${i + 1}'),
        ],
      ),
    ];
  }

  Marker _marcadorPunto(LatLng punto, String texto) => Marker(
        point: punto,
        width: 28,
        height: 28,
        child: Container(
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            texto,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final pos = _ubicacion.posicion;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.borrador.tipo.etiqueta}: zona (2/2)')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _ubicacion.posicionOPorDefecto,
                    initialZoom: 16,
                    minZoom: 3,
                    maxZoom: 19,
                    onTap: _onTapMapa,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    capaOpenStreetMap(),
                    ..._capasBorrador(),
                    if (pos != null)
                      MarkerLayer(markers: [marcadorUsuario(pos, simulada: _ubicacion.esSimulada)]),
                    atribucionOpenStreetMap(),
                  ],
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(widget.borrador.tipo.instruccionesZona),
                    ),
                  ),
                ),
                if (pos != null)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      heroTag: null,
                      tooltip: 'Mi ubicación',
                      onPressed: () => _mapController.move(pos, 17),
                      child: const Icon(Icons.my_location),
                    ),
                  ),
              ],
            ),
          ),

          // Panel inferior: estado, radio y acciones
          Material(
            elevation: 8,
            color: tema.colorScheme.surfaceContainer,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_estado, style: tema.textTheme.bodyLarge),
                    if (_geometria == GeometriaZona.circulo && _centro != null)
                      Slider(
                        value: _radio,
                        min: _radioMinimo,
                        max: _radioMaximo,
                        divisions: ((_radioMaximo - _radioMinimo) / 50).round(),
                        label: formatearDistancia(_radio),
                        onChanged: _guardando ? null : (v) => setState(() => _radio = v),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: _hayAlgo && !_guardando ? _deshacer : null,
                          icon: const Icon(Icons.undo),
                          label: const Text('Deshacer'),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _completa && !_guardando ? _guardar : null,
                          icon: _guardando
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check),
                          label: Text(_guardando ? 'Publicando…' : 'Publicar incidencia'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
