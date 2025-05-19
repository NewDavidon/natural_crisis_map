import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Servicio que encapsula todas las operaciones de autenticación
/// (login, registro y logout) usando Firebase Auth.
class AuthService {
  /// Instancia única de FirebaseAuth.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Inicia sesión con email y contraseña.
  ///
  /// ▸ **Modo debug con credenciales de prueba:**  
  ///    Si compilas en `kDebugMode` y escribes `user / user`, la función
  ///    inicia sesión de forma anónima para no depender de la red
  ///    mientras desarrollas.  
  /// ▸ **Producción:** login real contra Firebase usando
  ///   `signInWithEmailAndPassword`.
  Future<UserCredential> signIn(String email, String password) async {
    if (kDebugMode && email == 'demo@demo.com' && password == 'demodemo') {
      return await _auth.signInAnonymously();
    }

    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Registra un nuevo usuario con email y contraseña.
  /// Después del alta, actualiza opcionalmente el `displayName`
  /// para que combine nombre y apellidos.
  Future<UserCredential> signUp(
    String email,
    String password, {
    String? firstName,
    String? lastName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (firstName != null || lastName != null) {
      await cred.user!.updateDisplayName(
        '$firstName $lastName'.trim(),
      );
    }
    return cred;
  }

  /// Cierra la sesión del usuario actual.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
