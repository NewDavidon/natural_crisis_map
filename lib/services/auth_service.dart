import 'package:firebase_auth/firebase_auth.dart';

/// Servicio que encapsula todas las operaciones de autenticación
/// (login, registro y logout) usando Firebase Auth.
class AuthService {
  /// Se obtiene bajo demanda para que la app (y los tests) puedan funcionar
  /// en modo demo aunque Firebase no esté inicializado.
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Inicia sesión con email y contraseña.
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Registra un nuevo usuario con email y contraseña.
  /// Después del alta, actualiza el `displayName` para que combine nombre
  /// y apellidos.
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
    final nombre = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (nombre.isNotEmpty) {
      await cred.user!.updateDisplayName(nombre);
    }
    return cred;
  }

  /// Envía el email para restablecer la contraseña.
  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Cierra la sesión del usuario actual.
  Future<void> signOut() => _auth.signOut();
}

/// Traduce los errores de Firebase Auth a mensajes comprensibles.
String mensajeErrorAuth(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'user-disabled':
        return 'Esta cuenta está desactivada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':
        return 'La contraseña es demasiado débil (mínimo 6 caracteres).';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu red o prueba el modo demo.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento y vuelve a probar.';
      case 'operation-not-allowed':
        return 'El inicio de sesión con email no está activado en Firebase.';
    }
    return error.message ?? 'Error de autenticación (${error.code}).';
  }
  return error.toString();
}
