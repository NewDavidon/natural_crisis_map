import 'dart:typed_data';

import 'package:crisis_map_natural/models/donacion.dart';
import 'package:crisis_map_natural/models/foto_incidencia.dart';
import 'package:crisis_map_natural/models/incidencia.dart';
import 'package:crisis_map_natural/models/punto_ayuda.dart';
import 'package:crisis_map_natural/models/tipo_incidencia.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  final fecha = DateTime(2026, 10, 15, 10, 30);

  group('Incidencia', () {
    test('toMap/fromMap conserva todos los datos de un polígono', () {
      final original = Incidencia(
        id: 'abc',
        tipo: TipoIncidencia.inundacion,
        titulo: 'Río desbordado',
        descripcion: 'No cruzar',
        gravedad: Gravedad.alta,
        fecha: fecha,
        userId: 'u1',
        autor: 'Ana',
        activa: false,
        vertices: const [LatLng(1, 1), LatLng(1, 2), LatLng(2, 2), LatLng(2, 1), LatLng(1.5, 0.5)],
      );

      final copia = Incidencia.fromMap(original.toMap(), 'abc');

      expect(copia.tipo, TipoIncidencia.inundacion);
      expect(copia.titulo, 'Río desbordado');
      expect(copia.gravedad, Gravedad.alta);
      expect(copia.fecha, fecha);
      expect(copia.autor, 'Ana');
      expect(copia.activa, isFalse);
      expect(copia.vertices, original.vertices);
    });

    test('lee el formato antiguo de 4 vértices v0Lat…v3Lng', () {
      final inc = Incidencia.fromMap({
        'tipo': 'inundacion',
        'titulo': 'Antigua',
        'fecha': fecha.toIso8601String(),
        for (var i = 0; i < 4; i++) ...{'v${i}Lat': 40.0 + i, 'v${i}Lng': -3.0 - i},
      }, 'old');

      expect(inc.vertices, hasLength(4));
      expect(inc.vertices!.last, const LatLng(43, -6));
      expect(inc.activa, isTrue);
      expect(inc.gravedad, Gravedad.media);
    });

    test('círculo y línea guardan sólo sus campos', () {
      final circulo = Incidencia(
        id: '1',
        tipo: TipoIncidencia.incendio,
        titulo: 'Fuego',
        descripcion: '',
        fecha: fecha,
        userId: 'u',
        centro: const LatLng(40, -3),
        radio: 250,
      ).toMap();
      expect(circulo['radio'], 250);
      expect(circulo.containsKey('inicioLat'), isFalse);

      final linea = Incidencia(
        id: '2',
        tipo: TipoIncidencia.calle_cortada,
        titulo: 'Corte',
        descripcion: '',
        fecha: fecha,
        userId: 'u',
        inicio: const LatLng(40, -3),
        fin: const LatLng(40.001, -3),
      );
      expect(linea.toMap().containsKey('radio'), isFalse);
      expect(linea.posicion.latitude, closeTo(40.0005, 1e-9));
    });

    test('valida los datos de ubicación según el tipo', () {
      expect(
        () => Incidencia(
          id: '1',
          tipo: TipoIncidencia.inundacion,
          titulo: 'x',
          descripcion: '',
          fecha: fecha,
          userId: 'u',
          vertices: const [LatLng(0, 0), LatLng(1, 1)],
        ),
        throwsArgumentError,
      );
      expect(
        () => Incidencia(
          id: '1',
          tipo: TipoIncidencia.zona_terremoto,
          titulo: 'x',
          descripcion: '',
          fecha: fecha,
          userId: 'u',
          centro: const LatLng(0, 0),
          radio: 0,
        ),
        throwsArgumentError,
      );
    });

    test('tipo desconocido se convierte en calle cortada', () {
      expect(tipoFromString('meteorito'), TipoIncidencia.calle_cortada);
      expect(tipoToString(TipoIncidencia.zona_terremoto), 'zona_terremoto');
    });
  });

  test('FotoIncidencia ida y vuelta en base64', () {
    final bytes = Uint8List.fromList(List.generate(256, (i) => i));
    final foto = FotoIncidencia(id: 'f', bytes: bytes, fecha: fecha, userId: 'u', autor: 'Ana');
    final copia = FotoIncidencia.fromMap(foto.toMap(), 'f');
    expect(copia.bytes, bytes);
    expect(FotoIncidencia.cabeEnFirestore(bytes), isTrue);
    expect(FotoIncidencia.cabeEnFirestore(Uint8List(800 * 1024)), isFalse);
  });

  test('PuntoAyuda ida y vuelta', () {
    final p = PuntoAyuda(
      id: 'p',
      tipo: TipoAyuda.sanitario,
      nombre: 'Puesto',
      contacto: 'Tel. 600 000 000',
      posicion: const LatLng(40.1, -3.2),
      fecha: fecha,
      userId: 'u',
    );
    final copia = PuntoAyuda.fromMap(p.toMap(), 'p');
    expect(copia.tipo, TipoAyuda.sanitario);
    expect(copia.posicion, const LatLng(40.1, -3.2));
    expect(copia.contacto, 'Tel. 600 000 000');
  });

  test('Donacion ida y vuelta', () {
    final d = Donacion(
      id: 'd',
      clase: ClaseDonacion.necesito,
      categoria: CategoriaDonacion.medicinas,
      descripcion: 'Insulina',
      fecha: fecha,
      userId: 'u',
      cubierta: true,
    );
    final copia = Donacion.fromMap(d.toMap(), 'd');
    expect(copia.clase, ClaseDonacion.necesito);
    expect(copia.categoria, CategoriaDonacion.medicinas);
    expect(copia.cubierta, isTrue);
  });
}
