import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'crisis_repository.dart';
import 'demo_repository.dart';
import 'firestore_repository.dart';

/// Datos básicos del usuario que está usando la app.
class Usuario {
  final String uid;
  final String nombre;
  final String? email;

  const Usuario({required this.uid, required this.nombre, this.email});
}

/// Estado global de la sesión: quién está conectado, si estamos en modo demo
/// y qué repositorio de datos usar.
class Sesion extends ChangeNotifier {
  Sesion._();
  static final instance = Sesion._();

  /// false si Firebase no se pudo inicializar (sin configuración o sin red).
  /// En ese caso sólo está disponible el modo demo.
  bool firebaseDisponible = false;

  bool _demo = false;
  CrisisRepository? _repo;

  static const _usuarioDemo = Usuario(uid: 'demo-usuario', nombre: 'Usuario demo');

  bool get esDemo => _demo;

  Usuario? get usuario {
    if (_demo) return _usuarioDemo;
    if (!firebaseDisponible) return null;
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return null;
    final nombre = (u.displayName?.trim().isNotEmpty ?? false)
        ? u.displayName!.trim()
        : (u.email?.split('@').first ?? 'Usuario');
    return Usuario(uid: u.uid, nombre: nombre, email: u.email);
  }

  /// Repositorio de datos según el modo actual.
  CrisisRepository get repo => _repo ??= _demo ? DemoRepository() : FirestoreRepository();

  /// Entra en modo demo: datos de ejemplo en memoria, sin cuenta.
  void iniciarDemo() {
    _demo = true;
    _repo = DemoRepository();
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    if (_demo) {
      _demo = false;
    } else if (firebaseDisponible) {
      await AuthService().signOut();
    }
    _repo = null;
    notifyListeners();
  }
}
