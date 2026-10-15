import 'package:crisis_map_natural/models/incidencia.dart';
import 'package:crisis_map_natural/models/tipo_incidencia.dart';
import 'package:crisis_map_natural/utils/formato.dart';
import 'package:crisis_map_natural/utils/geo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const sol = LatLng(40.4168, -3.7038);
  // Una milésima de grado de latitud al norte de Sol (≈111 m).
  final unaMilesimaNorte = distanciaMetros(sol, const LatLng(40.4178, -3.7038));

  group('distanciaASegmento', () {
    test('punto sobre el segmento da 0', () {
      final d = distanciaASegmento(sol, const LatLng(40.4160, -3.7038), const LatLng(40.4180, -3.7038));
      expect(d, closeTo(0, 0.5));
    });

    test('punto perpendicular al segmento', () {
      // Segmento horizontal 1 milésima de grado al norte (≈110 m).
      final d = distanciaASegmento(sol, const LatLng(40.4178, -3.7050), const LatLng(40.4178, -3.7020));
      expect(d, closeTo(unaMilesimaNorte, 1));
    });

    test('fuera del segmento se mide al extremo más cercano', () {
      final extremo = const LatLng(40.4178, -3.7038);
      final d = distanciaASegmento(sol, extremo, const LatLng(40.4188, -3.7038));
      expect(d, closeTo(distanciaMetros(sol, extremo), 1));
    });
  });

  group('puntoEnPoligono', () {
    const cuadrado = [
      LatLng(40.0, -4.0),
      LatLng(40.0, -3.0),
      LatLng(41.0, -3.0),
      LatLng(41.0, -4.0),
    ];

    test('dentro', () => expect(puntoEnPoligono(const LatLng(40.5, -3.5), cuadrado), isTrue));
    test('fuera', () => expect(puntoEnPoligono(const LatLng(42.0, -3.5), cuadrado), isFalse));
  });

  group('distanciaAIncidencia', () {
    Incidencia base(TipoIncidencia tipo, {LatLng? inicio, LatLng? fin, LatLng? centro, double? radio, List<LatLng>? vertices}) =>
        Incidencia(
          id: 'x',
          tipo: tipo,
          titulo: 't',
          descripcion: '',
          fecha: DateTime(2026),
          userId: 'u',
          inicio: inicio,
          fin: fin,
          centro: centro,
          radio: radio,
          vertices: vertices,
        );

    test('círculo: 0 si estás dentro del radio', () {
      final inc = base(TipoIncidencia.incendio, centro: const LatLng(40.4170, -3.7038), radio: 100);
      expect(distanciaAIncidencia(sol, inc), 0);
    });

    test('círculo: distancia al borde si estás fuera', () {
      final centro = const LatLng(40.4268, -3.7038); // ≈1,1 km al norte
      final inc = base(TipoIncidencia.zona_terremoto, centro: centro, radio: 500);
      expect(distanciaAIncidencia(sol, inc), closeTo(distanciaMetros(sol, centro) - 500, 1));
    });

    test('polígono: 0 dentro, distancia al borde fuera', () {
      final dentro = base(TipoIncidencia.inundacion, vertices: const [
        LatLng(40.4160, -3.7050),
        LatLng(40.4160, -3.7020),
        LatLng(40.4180, -3.7020),
        LatLng(40.4180, -3.7050),
      ]);
      expect(distanciaAIncidencia(sol, dentro), 0);

      final fuera = base(TipoIncidencia.inundacion, vertices: const [
        LatLng(40.4178, -3.7050),
        LatLng(40.4178, -3.7020),
        LatLng(40.4190, -3.7020),
        LatLng(40.4190, -3.7050),
      ]);
      expect(distanciaAIncidencia(sol, fuera), closeTo(unaMilesimaNorte, 1));
    });

    test('línea: distancia al tramo', () {
      final inc = base(
        TipoIncidencia.calle_cortada,
        inicio: const LatLng(40.4178, -3.7050),
        fin: const LatLng(40.4178, -3.7020),
      );
      expect(distanciaAIncidencia(sol, inc), closeTo(unaMilesimaNorte, 1));
    });
  });

  group('formato', () {
    test('distancias', () {
      expect(formatearDistancia(350.4), '350 m');
      expect(formatearDistancia(1250), '1,3 km');
      expect(formatearDistancia(12400), '12 km');
    });

    test('fechas relativas', () {
      final ahora = DateTime(2026, 10, 15, 12);
      expect(formatearFecha(ahora.subtract(const Duration(seconds: 20)), ahora: ahora), 'hace un momento');
      expect(formatearFecha(ahora.subtract(const Duration(minutes: 5)), ahora: ahora), 'hace 5 min');
      expect(formatearFecha(ahora.subtract(const Duration(hours: 3)), ahora: ahora), 'hace 3 h');
      expect(formatearFecha(ahora.subtract(const Duration(days: 1)), ahora: ahora), 'hace 1 día');
      expect(formatearFecha(DateTime(2026, 9, 1, 8, 5), ahora: ahora), '01/09/2026 08:05');
    });
  });
}
