// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/map_screen.dart';
import 'screens/incidencia_form_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Incidencias',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login'           : (ctx) => const LoginScreen(),
        '/register'        : (ctx) => const RegisterScreen(),
        '/forgot-password' : (ctx) => const ForgotPasswordScreen(),
        '/map'             : (ctx) => const MapScreen(),
        '/nuevo-informe'   : (ctx) => const IncidenciaFormScreen(),
      },
    );
  }
}
