import 'package:crisis_map_natural/models/incidencia.dart';
import 'package:crisis_map_natural/models/tipo_incidencia.dart';
import 'package:crisis_map_natural/services/alertas_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

Incidencia _incendio(String id, LatLng centro, {String userId = 'otro', bool activa = true}) => Incidencia(
      id: id,
      tipo: TipoIncidencia.incendio,
      titulo: 'Incendio $id',
      descripcion: '',
      fecha: DateTime(2026),
      userId: userId,
      activa: activa,
      centro: centro,
      radio: 100,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  const yo = LatLng(40.4168, -3.7038);
  const lejos = LatLng(40.5168, -3.7038); // ≈11 km al norte

  final cerca = _incendio('cerca', const LatLng(40.4208, -3.7038)); // ≈450 m (borde a ≈350 m)
  final muyLejos = _incendio('lejos', lejos);

  late AlertasService alertas;
  setUp(() => alertas = AlertasService());

  test('avisa una sola vez de cada incidencia dentro del radio', () {
    final primera = alertas.evaluar(yo, [cerca, muyLejos], uidActual: 'yo');
    expect(primera.map((c) => c.incidencia.id), ['cerca']);
    expect(primera.single.distancia, closeTo(345, 5));
    expect(alertas.cercanas, hasLength(1));

    final segunda = alertas.evaluar(yo, [cerca, muyLejos], uidActual: 'yo');
    expect(segunda, isEmpty, reason: 'ya se avisó');
    expect(alertas.cercanas, hasLength(1), reason: 'sigue estando cerca');
  });

  test('vuelve a avisar si te alejas y regresas', () {
    alertas.evaluar(yo, [cerca]);
    expect(alertas.evaluar(lejos, [cerca]), isEmpty);
    expect(alertas.cercanas, isEmpty);
    expect(alertas.evaluar(yo, [cerca]), hasLength(1));
  });

  test('ignora incidencias propias y resueltas', () {
    final propia = _incendio('propia', const LatLng(40.4170, -3.7038), userId: 'yo');
    final resuelta = _incendio('resuelta', const LatLng(40.4170, -3.7038), activa: false);
    final nuevas = alertas.evaluar(yo, [propia, resuelta], uidActual: 'yo');
    expect(nuevas, isEmpty);
    // La propia sí cuenta como cercana (se ve en el banner), la resuelta no.
    expect(alertas.cercanas.map((c) => c.incidencia.id), ['propia']);
    expect(alertas.cercanas.single.dentro, isTrue);
  });

  test('respeta el radio y la opción de desactivar', () async {
    await alertas.cambiarAjustes(radioMetros: 500);
    expect(alertas.evaluar(yo, [_incendio('a', const LatLng(40.4238, -3.7038))]), isEmpty); // ≈680 m

    await alertas.cambiarAjustes(activadas: false, radioMetros: 1000);
    final b = _incendio('b', const LatLng(40.4238, -3.7038));
    expect(alertas.evaluar(yo, [b]), isEmpty);
    expect(alertas.cercanas, hasLength(1), reason: 'el banner sigue informando');

    await alertas.cambiarAjustes(activadas: true);
    expect(alertas.evaluar(yo, [b]), hasLength(1));
  });

  test('los ajustes se guardan en el dispositivo', () async {
    await alertas.cambiarAjustes(activadas: false, radioMetros: 5000);
    final otra = AlertasService();
    await otra.cargarAjustes();
    expect(otra.activadas, isFalse);
    expect(otra.radioMetros, 5000);
  });

  test('sin ubicación no hay alertas', () {
    expect(alertas.evaluar(null, [cerca]), isEmpty);
    expect(alertas.cercanas, isEmpty);
  });
}
