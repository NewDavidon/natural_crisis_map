// lib/main.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/sesion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    Sesion.instance.firebaseDisponible = true;
  } catch (e) {
    // Sin Firebase la app sigue funcionando en modo demo.
    debugPrint('Firebase no disponible: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static ThemeData _tema(Brightness brillo) {
    final esquema = ColorScheme.fromSeed(
      seedColor: const Color(0xFFD84315),
      brightness: brillo,
    );
    return ThemeData(
      colorScheme: esquema,
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crisis Map',
      debugShowCheckedModeBanner: false,
      theme: _tema(Brightness.light),
      darkTheme: _tema(Brightness.dark),
      home: const AuthGate(),
      routes: {
        '/register'        : (ctx) => const RegisterScreen(),
        '/forgot-password' : (ctx) => const ForgotPasswordScreen(),
      },
    );
  }
}

/// Muestra el login o la pantalla principal según haya sesión iniciada
/// (cuenta de Firebase o modo demo).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // `userChanges` también avisa cuando se actualiza el nombre tras el registro.
  final Stream<User?>? _usuarios =
      Sesion.instance.firebaseDisponible ? FirebaseAuth.instance.userChanges() : null;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Sesion.instance,
      builder: (context, _) {
        if (Sesion.instance.esDemo) return const HomeScreen(key: ValueKey('demo'));
        if (_usuarios == null) return const LoginScreen();

        return StreamBuilder<User?>(
          stream: _usuarios,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final user = snapshot.data;
            return user != null
                ? HomeScreen(key: ValueKey(user.uid))
                : const LoginScreen();
          },
        );
      },
    );
  }
}
