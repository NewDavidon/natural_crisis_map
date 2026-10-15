import 'dart:async';

import 'package:flutter/material.dart';

import '../models/foto_incidencia.dart';
import '../models/incidencia.dart';
import '../models/tipo_incidencia.dart';
import '../services/sesion.dart';
import '../services/ubicacion_service.dart';
import '../utils/formato.dart';
import '../utils/geo.dart';
import 'fotos.dart';

/// Abre la ficha de una incidencia en una hoja inferior.
Future<void> mostrarDetalleIncidencia(
  BuildContext context,
  Incidencia incidencia, {
  VoidCallback? onVerEnMapa,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => _DetalleIncidencia(
        incidencia: incidencia,
        scrollController: scroll,
        onVerEnMapa: onVerEnMapa,
      ),
    ),
  );
}

class _DetalleIncidencia extends StatefulWidget {
  const _DetalleIncidencia({
    required this.incidencia,
    required this.scrollController,
    this.onVerEnMapa,
  });

  final Incidencia incidencia;
  final ScrollController scrollController;
  final VoidCallback? onVerEnMapa;

  @override
  State<_DetalleIncidencia> createState() => _DetalleIncidenciaState();
}

class _DetalleIncidenciaState extends State<_DetalleIncidencia> {
  final _repo = Sesion.instance.repo;
  // Una sola suscripción: las fotos están dentro de un ListView que puede
  // destruir y recrear sus hijos al hacer scroll.
  StreamSubscription<List<FotoIncidencia>>? _suscripcionFotos;
  List<FotoIncidencia>? _fotos;
  bool _errorFotos = false;
  bool _subiendoFoto = false;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _suscripcionFotos = _repo.fotos(widget.incidencia.id).listen(
          (fotos) => setState(() {
            _fotos = fotos;
            _errorFotos = false;
          }),
          onError: (Object _) => setState(() => _errorFotos = true),
        );
  }

  @override
  void dispose() {
    _suscripcionFotos?.cancel();
    super.dispose();
  }

  Widget _galeria(ThemeData tema) {
    if (_errorFotos) return const Text('No se pudieron cargar las fotos.');
    final fotos = _fotos;
    if (fotos == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (fotos.isEmpty) {
      return Text(
        'Aún no hay fotos. Si estás en la zona y es seguro, añade una para ayudar a otros.',
        style: tema.textTheme.bodySmall,
      );
    }
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: fotos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => MiniaturaFoto(bytes: fotos[i].bytes, tamano: 104),
      ),
    );
  }

  Incidencia get _inc => widget.incidencia;
  bool get _esMia => Sesion.instance.usuario?.uid == _inc.userId;

  Future<void> _anadirFoto() async {
    final usuario = Sesion.instance.usuario;
    if (usuario == null) return;
    final bytes = await elegirFoto(context);
    if (bytes == null || !mounted) return;
    setState(() => _subiendoFoto = true);
    try {
      await _repo.anadirFoto(
        _inc.id,
        FotoIncidencia(
          id: '',
          bytes: bytes,
          fecha: DateTime.now(),
          userId: usuario.uid,
          autor: usuario.nombre,
        ),
      );
    } catch (e) {
      _avisar('No se pudo subir la foto: $e');
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _cambiarEstado() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _ocupado = true);
    try {
      await _repo.marcarIncidenciaActiva(_inc.id, !_inc.activa);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
        content: Text(_inc.activa ? 'Incidencia marcada como resuelta' : 'Incidencia reactivada'),
      ));
    } catch (e) {
      _avisar('No se pudo actualizar: $e');
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _borrar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar incidencia?'),
        content: const Text('Se borrarán también sus fotos. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _ocupado = true);
    try {
      await _repo.borrarIncidencia(_inc.id);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Incidencia eliminada')));
    } catch (e) {
      _avisar('No se pudo eliminar: $e');
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  String get _detalleZona {
    switch (_inc.tipo.geometria) {
      case GeometriaZona.linea:
        return 'Tramo afectado de ${formatearDistancia(distanciaMetros(_inc.inicio!, _inc.fin!))}';
      case GeometriaZona.circulo:
        return 'Radio afectado: ${formatearDistancia(_inc.radio!)}';
      case GeometriaZona.poligono:
        return 'Zona delimitada por ${_inc.vertices!.length} puntos';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final posicion = UbicacionService.instance.posicion;
    final distancia = posicion == null ? null : distanciaAIncidencia(posicion, _inc);

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: _inc.tipo.color,
              foregroundColor: Colors.white,
              child: Icon(_inc.tipo.icono),
            ),
            const SizedBox(width: 12),
            Text(_inc.tipo.etiqueta, style: tema.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 12),
        Text(_inc.titulo, style: tema.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Chip(
              avatar: Icon(Icons.priority_high, color: _inc.gravedad.color, size: 18),
              label: Text('Gravedad ${_inc.gravedad.etiqueta.toLowerCase()}'),
            ),
            if (!_inc.activa)
              const Chip(avatar: Icon(Icons.check_circle, size: 18), label: Text('Resuelta')),
            if (distancia != null)
              Chip(
                avatar: const Icon(Icons.near_me, size: 18),
                label: Text(distancia == 0
                    ? 'Estás dentro de la zona'
                    : 'A ${formatearDistancia(distancia)} de ti'),
              ),
          ],
        ),
        if (_inc.descripcion.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(_inc.descripcion, style: tema.textTheme.bodyLarge),
        ],
        const SizedBox(height: 12),
        Text(_detalleZona, style: tema.textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          'Reportado por ${_inc.autor.isEmpty ? 'un usuario' : _inc.autor} · ${formatearFecha(_inc.fecha)}',
          style: tema.textTheme.bodySmall,
        ),
        const Divider(height: 32),

        // — Fotos —
        Row(
          children: [
            Expanded(child: Text('Fotos', style: tema.textTheme.titleMedium)),
            if (_subiendoFoto)
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              TextButton.icon(
                onPressed: _anadirFoto,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Añadir'),
              ),
          ],
        ),
        _galeria(tema),
        const SizedBox(height: 8),

        // — Consejos —
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: const Icon(Icons.health_and_safety),
            title: const Text('Qué hacer: consejos de seguridad'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [
              for (final consejo in _inc.tipo.consejos)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check, size: 18),
                  title: Text(consejo),
                ),
            ],
          ),
        ),

        if (widget.onVerEnMapa != null) ...[
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.pop(context);
              widget.onVerEnMapa!();
            },
            icon: const Icon(Icons.map),
            label: const Text('Ver en el mapa'),
          ),
        ],

        if (_esMia) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _ocupado ? null : _cambiarEstado,
                  icon: Icon(_inc.activa ? Icons.check_circle_outline : Icons.restart_alt),
                  label: Text(_inc.activa ? 'Marcar resuelta' : 'Reactivar'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _ocupado ? null : _borrar,
                style: TextButton.styleFrom(foregroundColor: tema.colorScheme.error),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
