import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../models/incidencia.dart';
import '../models/punto_ayuda.dart';
import '../models/tipo_incidencia.dart';
import '../services/alertas_service.dart';
import '../services/sesion.dart';
import '../services/ubicacion_service.dart';
import '../utils/formato.dart';
import '../widgets/ajustes_alertas.dart';
import '../widgets/detalle_incidencia.dart';
import '../widgets/detalle_punto_ayuda.dart';
import 'ayuda_screen.dart';
import 'donacion_form_screen.dart';
import 'donaciones_screen.dart';
import 'incidencia_form_screen.dart';
import 'incidencias_list_screen.dart';
import 'map_screen.dart';
import 'punto_ayuda_form_screen.dart';

/// Pantalla principal tras iniciar sesión: mapa, lista de incidencias,
/// ayuda y donaciones. También vigila las incidencias cercanas y lanza
/// las alertas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _titulos = ['Mapa de crisis', 'Incidencias', 'Ayuda', 'Donaciones'];

  final _sesion = Sesion.instance;
  final _ubicacion = UbicacionService.instance;
  final _alertas = AlertasService.instance;
  final _foco = FocoMapa();

  int _pestana = 0;
  List<Incidencia> _incidencias = const [];
  List<PuntoAyuda> _puntosAyuda = const [];
  String? _errorDatos;
  bool _dialogoAlertaAbierto = false;
  StreamSubscription<List<Incidencia>>? _subIncidencias;
  StreamSubscription<List<PuntoAyuda>>? _subAyuda;

  @override
  void initState() {
    super.initState();
    final repo = _sesion.repo;
    _subIncidencias = repo.incidencias().listen(
      (lista) {
        setState(() {
          _incidencias = lista;
          _errorDatos = null;
        });
        _evaluarAlertas();
      },
      onError: _onErrorDatos,
    );
    _subAyuda = repo.puntosAyuda().listen(
      (lista) => setState(() => _puntosAyuda = lista),
      onError: _onErrorDatos,
    );

    _alertas.reiniciar();
    _alertas.cargarAjustes().then((_) => _evaluarAlertas());
    _ubicacion.addListener(_evaluarAlertas);
    _ubicacion.iniciar();
  }

  @override
  void dispose() {
    _subIncidencias?.cancel();
    _subAyuda?.cancel();
    _ubicacion.removeListener(_evaluarAlertas);
    _ubicacion.detener();
    _foco.dispose();
    super.dispose();
  }

  void _onErrorDatos(Object error) {
    if (!mounted) return;
    var mensaje = 'No se pudieron cargar los datos: $error';
    if (error is FirebaseException && error.code == 'permission-denied') {
      mensaje = 'Firestore ha denegado el acceso. Publica las reglas de '
          'firestore.rules en tu proyecto de Firebase.';
    }
    setState(() => _errorDatos = mensaje);
  }

  // — Alertas de cercanía —

  void _evaluarAlertas() {
    if (!mounted) return;
    final nuevas = _alertas.evaluar(
      _ubicacion.posicion,
      _incidencias,
      uidActual: _sesion.usuario?.uid,
    );
    if (nuevas.isNotEmpty) _mostrarAlerta(nuevas);
  }

  Future<void> _mostrarAlerta(List<IncidenciaCercana> nuevas) async {
    HapticFeedback.heavyImpact();
    if (_dialogoAlertaAbierto) return; // El banner del mapa ya las muestra.
    _dialogoAlertaAbierto = true;

    final colores = Theme.of(context).colorScheme;
    final titulo = nuevas.any((c) => c.dentro)
        ? 'Estás en una zona afectada'
        : nuevas.length == 1
            ? 'Incidencia cerca de ti'
            : '${nuevas.length} incidencias cerca de ti';

    final elegida = await showDialog<Incidencia>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: colores.error, size: 48),
        title: Text(titulo),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final c in nuevas.take(5))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Navigator.pop(ctx, c.incidencia),
                  leading: CircleAvatar(
                    backgroundColor: c.incidencia.tipo.color,
                    foregroundColor: Colors.white,
                    child: Icon(c.incidencia.tipo.icono),
                  ),
                  title: Text(c.incidencia.titulo),
                  subtitle: Text(
                    '${c.incidencia.tipo.etiqueta} · '
                    '${c.dentro ? 'estás dentro' : 'a ${formatearDistancia(c.distancia)}'}',
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nuevas.first.incidencia),
            child: const Text('Ver en el mapa'),
          ),
        ],
      ),
    );

    _dialogoAlertaAbierto = false;
    if (elegida != null && mounted) {
      _verEnMapa(elegida.posicion);
      mostrarDetalleIncidencia(context, elegida);
    }
  }

  // — Navegación —

  void _verEnMapa(LatLng punto) {
    setState(() => _pestana = 0);
    _foco.enfocar(punto);
  }

  void _abrirIncidencia(Incidencia inc) {
    mostrarDetalleIncidencia(
      context,
      inc,
      onVerEnMapa: _pestana == 0 ? null : () => _verEnMapa(inc.posicion),
    );
  }

  void _abrirPuntoAyuda(PuntoAyuda punto) {
    mostrarDetallePuntoAyuda(
      context,
      punto,
      onVerEnMapa: _pestana == 0 ? null : () => _verEnMapa(punto.posicion),
    );
  }

  void _reportarIncidencia() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const IncidenciaFormScreen()),
    );
  }

  void _anadirPuntoAyuda([LatLng? posicion]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PuntoAyudaFormScreen(
          posicionInicial: posicion ?? _foco.centroVisible ?? _ubicacion.posicionOPorDefecto,
        ),
      ),
    );
  }

  void _publicarDonacion() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DonacionFormScreen()),
    );
  }

  Future<void> _menuReportar() async {
    final opcion = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Reportar una incidencia'),
              subtitle: const Text('Calle cortada, inundación, terremoto, incendio…'),
              onTap: () => Navigator.pop(ctx, 0),
            ),
            ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: const Text('Añadir un punto de ayuda'),
              subtitle: const Text('Albergue, agua y comida, atención sanitaria…'),
              onTap: () => Navigator.pop(ctx, 1),
            ),
          ],
        ),
      ),
    );
    if (opcion == 0) _reportarIncidencia();
    if (opcion == 1) _anadirPuntoAyuda();
  }

  /// Mantener pulsado el mapa: añadir ayuda ahí o (en demo) simular ubicación.
  Future<void> _onLongPressMapa(LatLng punto) async {
    final opcion = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: const Text('Añadir un punto de ayuda aquí'),
              onTap: () => Navigator.pop(ctx, 0),
            ),
            if (_sesion.esDemo)
              ListTile(
                leading: const Icon(Icons.person_pin_circle),
                title: const Text('Simular que estoy aquí'),
                subtitle: const Text('Modo demo: prueba las alertas de cercanía'),
                onTap: () => Navigator.pop(ctx, 1),
              ),
          ],
        ),
      ),
    );
    if (opcion == 0) _anadirPuntoAyuda(punto);
    if (opcion == 1) _ubicacion.simular(punto);
  }

  Future<void> _cerrarSesion() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_sesion.esDemo ? '¿Salir del modo demo?' : '¿Cerrar sesión?'),
        content: _sesion.esDemo
            ? const Text('Los datos de prueba que hayas añadido se perderán.')
            : null,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
        ],
      ),
    );
    if (confirmado == true) await _sesion.cerrarSesion();
  }

  // — Interfaz —

  Widget? _botonFlotante() {
    switch (_pestana) {
      case 0:
      case 1:
        return FloatingActionButton.extended(
          onPressed: _menuReportar,
          icon: const Icon(Icons.add_alert),
          label: const Text('Reportar'),
        );
      case 2:
        return FloatingActionButton.extended(
          onPressed: _anadirPuntoAyuda,
          icon: const Icon(Icons.add_location_alt),
          label: const Text('Punto de ayuda'),
        );
      case 3:
        return FloatingActionButton.extended(
          onPressed: _publicarDonacion,
          icon: const Icon(Icons.add),
          label: const Text('Publicar'),
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _sesion.usuario;
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_pestana]),
        actions: [
          if (_sesion.esDemo)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Chip(label: Text('DEMO'), visualDensity: VisualDensity.compact),
            ),
          ListenableBuilder(
            listenable: _alertas,
            builder: (context, _) => IconButton(
              tooltip: 'Alertas de cercanía',
              icon: Icon(_alertas.activadas
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined),
              onPressed: () => mostrarAjustesAlertas(context, onCambio: _evaluarAlertas),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Cuenta',
            icon: CircleAvatar(
              radius: 16,
              child: Text((usuario?.nombre.isNotEmpty ?? false)
                  ? usuario!.nombre[0].toUpperCase()
                  : '?'),
            ),
            onSelected: (valor) {
              if (valor == 'salir') _cerrarSesion();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                enabled: false,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person),
                  title: Text(usuario?.nombre ?? 'Usuario'),
                  subtitle: Text(usuario?.email ?? (_sesion.esDemo ? 'Modo demo' : '')),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'salir',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout),
                  title: Text(_sesion.esDemo ? 'Salir del modo demo' : 'Cerrar sesión'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_errorDatos != null)
            MaterialBanner(
              backgroundColor: colores.errorContainer,
              leading: Icon(Icons.cloud_off, color: colores.onErrorContainer),
              content: Text(_errorDatos!, style: TextStyle(color: colores.onErrorContainer)),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _errorDatos = null),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          Expanded(
            child: IndexedStack(
              index: _pestana,
              children: [
                MapScreen(
                  incidencias: _incidencias,
                  puntosAyuda: _puntosAyuda,
                  foco: _foco,
                  onTapIncidencia: _abrirIncidencia,
                  onTapPuntoAyuda: _abrirPuntoAyuda,
                  onLongPress: _onLongPressMapa,
                ),
                IncidenciasListScreen(
                  incidencias: _incidencias,
                  onTapIncidencia: _abrirIncidencia,
                ),
                AyudaScreen(
                  puntosAyuda: _puntosAyuda,
                  onTapPuntoAyuda: _abrirPuntoAyuda,
                ),
                const DonacionesScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _botonFlotante(),
      bottomNavigationBar: ListenableBuilder(
        listenable: _alertas,
        builder: (context, _) {
          final cercanas = _alertas.cercanas.length;
          return NavigationBar(
            selectedIndex: _pestana,
            onDestinationSelected: (i) => setState(() => _pestana = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Mapa',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: cercanas > 0,
                  label: Text('$cercanas'),
                  child: const Icon(Icons.warning_amber_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: cercanas > 0,
                  label: Text('$cercanas'),
                  child: const Icon(Icons.warning_amber),
                ),
                label: 'Incidencias',
              ),
              const NavigationDestination(
                icon: Icon(Icons.health_and_safety_outlined),
                selectedIcon: Icon(Icons.health_and_safety),
                label: 'Ayuda',
              ),
              const NavigationDestination(
                icon: Icon(Icons.volunteer_activism_outlined),
                selectedIcon: Icon(Icons.volunteer_activism),
                label: 'Donar',
              ),
            ],
          );
        },
      ),
    );
  }
}
