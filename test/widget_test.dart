import 'package:crisis_map_natural/main.dart';
import 'package:crisis_map_natural/services/sesion.dart';
import 'package:crisis_map_natural/services/ubicacion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// En los tests no hay Firebase, así que la app arranca en el login y se
/// prueba con el modo demo.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('login ofrece el modo demo cuando Firebase no está disponible', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Probar en modo demo'), findsOneWidget);
    expect(find.textContaining('No se pudo conectar con Firebase'), findsOneWidget);
  });

  testWidgets('modo demo: pestañas, alerta de cercanía y salir', (tester) async {
    // La fuente de los tests (Ahem) es mucho más ancha que la real, así que
    // usamos una pantalla ancha para que la atribución del mapa quepa.
    tester.view.physicalSize = const Size(2000, 3000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.text('Probar en modo demo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(Sesion.instance.esDemo, isTrue);
    expect(find.text('Mapa de crisis'), findsOneWidget);
    expect(find.text('DEMO'), findsOneWidget);

    // Simulamos estar en la Puerta del Sol: la Gran Vía cortada está a ~350 m.
    UbicacionService.instance.simular(const LatLng(40.4168, -3.7038));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Incidencia cerca de ti'), findsOneWidget);
    expect(find.text('Gran Vía cortada por desprendimiento'), findsWidgets);
    await tester.tap(find.text('Entendido'));
    await tester.pump(const Duration(milliseconds: 500));

    // Lista de incidencias
    await tester.tap(find.text('Incidencias').last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Desbordamiento junto a Madrid Río'), findsOneWidget);

    // Ayuda
    await tester.tap(find.text('Ayuda'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Llamar al 112'), findsOneWidget);
    expect(find.text('Plaza Mayor'), findsOneWidget);

    // Donaciones
    await tester.tap(find.text('Donar'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Cruz Roja Española'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Tablón solidario'), 200);
    expect(find.text('Tablón solidario'), findsOneWidget);
    // Bajar y subir recrea los hijos del ListView: el tablón debe seguir
    // mostrándose (antes fallaba con "Stream has already been listened to").
    const ultima = 'Habitación libre para una familia durante una semana.';
    await tester.scrollUntilVisible(find.text(ultima), 300);
    await tester.scrollUntilVisible(find.text('Cruz Roja Española'), -300);
    await tester.scrollUntilVisible(find.text(ultima), 300);
    expect(find.text(ultima), findsOneWidget);

    // Salir del modo demo vuelve al login
    await Sesion.instance.cerrarSesion();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Probar en modo demo'), findsOneWidget);
  });
}
