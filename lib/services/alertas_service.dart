import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/incidencia.dart';
import '../utils/geo.dart';

/// Incidencia que está dentro del radio de alerta del usuario.
class IncidenciaCercana {
  final Incidencia incidencia;

  /// Distancia en metros hasta la zona afectada (0 = estás dentro).
  final double distancia;

  const IncidenciaCercana(this.incidencia, this.distancia);

  bool get dentro => distancia == 0;
}

/// Calcula qué incidencias están cerca del usuario y decide cuándo avisar.
///
/// Cada incidencia se avisa una sola vez mientras siga dentro del radio; si
/// el usuario se aleja y vuelve a acercarse, se avisa de nuevo.
class AlertasService extends ChangeNotifier {
  AlertasService();
  static final instance = AlertasService();

  static const radiosDisponibles = <double>[500, 1000, 2000, 5000, 10000];
  static const _claveActivadas = 'alertas_activadas';
  static const _claveRadio = 'alertas_radio';

  bool _activadas = true;
  double _radioMetros = 1000;
  final Set<String> _yaAvisadas = {};
  List<IncidenciaCercana> _cercanas = const [];

  bool get activadas => _activadas;
  double get radioMetros => _radioMetros;

  /// Incidencias activas dentro del radio, de la más cercana a la más lejana.
  List<IncidenciaCercana> get cercanas => _cercanas;

  /// Carga los ajustes guardados en el dispositivo.
  Future<void> cargarAjustes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _activadas = prefs.getBool(_claveActivadas) ?? _activadas;
      _radioMetros = prefs.getDouble(_claveRadio) ?? _radioMetros;
      notifyListeners();
    } catch (e) {
      debugPrint('No se pudieron cargar los ajustes de alertas: $e');
    }
  }

  Future<void> cambiarAjustes({bool? activadas, double? radioMetros}) async {
    _activadas = activadas ?? _activadas;
    _radioMetros = radioMetros ?? _radioMetros;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_claveActivadas, _activadas);
      await prefs.setDouble(_claveRadio, _radioMetros);
    } catch (e) {
      debugPrint('No se pudieron guardar los ajustes de alertas: $e');
    }
  }

  /// Recalcula las incidencias cercanas a [posicion] y devuelve las que hay
  /// que notificar ahora (las que acaban de entrar en el radio).
  ///
  /// Se ignoran las incidencias resueltas y las creadas por [uidActual].
  List<IncidenciaCercana> evaluar(
    LatLng? posicion,
    List<Incidencia> incidencias, {
    String? uidActual,
  }) {
    if (posicion == null) {
      _cercanas = const [];
      notifyListeners();
      return const [];
    }

    final cercanas = <IncidenciaCercana>[
      for (final inc in incidencias)
        if (inc.activa) IncidenciaCercana(inc, distanciaAIncidencia(posicion, inc)),
    ].where((c) => c.distancia <= _radioMetros).toList()
      ..sort((a, b) => a.distancia.compareTo(b.distancia));
    _cercanas = cercanas;

    // Olvidamos las que ya no están cerca para poder volver a avisar.
    final idsCercanas = cercanas.map((c) => c.incidencia.id).toSet();
    _yaAvisadas.removeWhere((id) => !idsCercanas.contains(id));

    var nuevas = const <IncidenciaCercana>[];
    if (_activadas) {
      nuevas = cercanas
          .where((c) =>
              c.incidencia.userId != uidActual &&
              !_yaAvisadas.contains(c.incidencia.id))
          .toList();
      _yaAvisadas.addAll(nuevas.map((c) => c.incidencia.id));
    }

    notifyListeners();
    return nuevas;
  }

  /// Olvida el estado (al cerrar sesión).
  void reiniciar() {
    _yaAvisadas.clear();
    _cercanas = const [];
  }
}
