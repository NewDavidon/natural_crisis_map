// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Importamos las pantallas que usaremos en las rutas
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/new_incident_screen.dart';

void main() async {
  // Asegura que Flutter esté inicializado antes de llamar a código asíncrono
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa Firebase (conecta la app con tu proyecto en la nube)
  await Firebase.initializeApp();
  // Arranca la aplicación
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Título de la app (usado por el SO)
      title: 'App Incidencias',
      // Oculta la etiqueta de debug en la esquina
      debugShowCheckedModeBanner: false,
      // Ruta inicial al arrancar
      initialRoute: '/login',
      // Definición de rutas nombradas
      routes: {
        '/login'           : (ctx) => const LoginScreen(),
        '/register'        : (ctx) => const RegisterScreen(),
        '/forgot-password' : (ctx) => const ForgotPasswordScreen(),
        // <-- Aquí quitamos `const`
        '/home'            : (ctx) => HomeScreen(),
        '/map'             : (ctx) => const MapScreen(),
        //'/new-incident'    : (ctx) => const NewIncidentScreen(),
      },
    );
  }
}
