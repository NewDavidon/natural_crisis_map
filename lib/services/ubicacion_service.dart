import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Sigue la ubicación del usuario y avisa a los oyentes cuando cambia.
///
/// En modo demo se puede [simular] una posición para probar las alertas
/// sin moverse.
class UbicacionService extends ChangeNotifier {
  UbicacionService._();
  static final instance = UbicacionService._();

  /// Centro por defecto si no hay ubicación: Madrid (Puerta del Sol).
  static const LatLng posicionPorDefecto = LatLng(40.4168, -3.7038);

  LatLng? _real;
  LatLng? _simulada;
  String? _error;
  bool _cargando = false;
  StreamSubscription<Position>? _suscripcion;

  /// Posición actual (simulada si la hay), o null si aún no se conoce.
  LatLng? get posicion => _simulada ?? _real;
  LatLng get posicionOPorDefecto => posicion ?? posicionPorDefecto;
  bool get esSimulada => _simulada != null;
  bool get cargando => _cargando;

  /// Mensaje si no se pudo obtener la ubicación real.
  String? get error => _error;

  /// Pide permisos y empieza a escuchar la ubicación. Se puede llamar varias
  /// veces: si ya está escuchando, no hace nada.
  Future<void> iniciar() async {
    if (_suscripcion != null || _cargando) return;
    _cargando = true;
    notifyListeners();

    try {
      // 1) Verificar si el servicio de ubicación está habilitado
      if (!await Geolocator.isLocationServiceEnabled()) {
        _error = 'La ubicación del dispositivo está desactivada.';
        return;
      }

      // 2) Verificar/solicitar permisos
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        _error = 'Sin permiso de ubicación: no podremos avisarte de incidencias cercanas.';
        return;
      }

      // 3) Posición inicial (con límite de tiempo) y escucha de cambios
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        _real = LatLng(pos.latitude, pos.longitude);
      } catch (_) {
        // Algunos dispositivos tardan en dar la primera posición; el stream
        // la enviará en cuanto la tenga.
      }
      _error = null;

      _suscripcion = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20, // metros
        ),
      ).listen(
        (pos) {
          _real = LatLng(pos.latitude, pos.longitude);
          _error = null;
          notifyListeners();
        },
        onError: (Object e) {
          _error = 'No se pudo actualizar la ubicación.';
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'No se pudo obtener la ubicación.';
      debugPrint('Error de ubicación: $e');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Fija una ubicación ficticia (o la quita con null).
  void simular(LatLng? posicion) {
    _simulada = posicion;
    notifyListeners();
  }

  /// Deja de escuchar la ubicación (al cerrar sesión).
  void detener() {
    _suscripcion?.cancel();
    _suscripcion = null;
    _simulada = null;
    notifyListeners();
  }
}
