// Los nombres del enum se guardan tal cual en Firestore, por eso mantienen
// el formato snake_case original.
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

/// Forma con la que se dibuja la zona afectada en el mapa.
enum GeometriaZona {
  /// Dos puntos: inicio y fin (p. ej. una calle cortada).
  linea,

  /// Centro + radio en metros.
  circulo,

  /// Polígono de 3 o más vértices.
  poligono,
}

/// Enum que representa los posibles tipos de incidencia
enum TipoIncidencia {
  calle_cortada,
  zona_terremoto,
  inundacion,
  incendio,
}

/// Función auxiliar para convertir un string a TipoIncidencia.
/// Útil para parsing si lees desde JSON / Firestore.
TipoIncidencia tipoFromString(String value) {
  return TipoIncidencia.values.firstWhere(
    (t) => t.name == value,
    // En caso de un valor desconocido, devolvemos uno por defecto
    orElse: () => TipoIncidencia.calle_cortada,
  );
}

/// Función auxiliar para convertir un TipoIncidencia a string.
/// Útil para toMap() o para persistir en Firestore como cadena.
String tipoToString(TipoIncidencia tipo) => tipo.name;

/// Datos de presentación y comportamiento de cada tipo.
extension TipoIncidenciaInfo on TipoIncidencia {
  String get etiqueta => switch (this) {
        TipoIncidencia.calle_cortada => 'Calle cortada',
        TipoIncidencia.zona_terremoto => 'Terremoto',
        TipoIncidencia.inundacion => 'Inundación',
        TipoIncidencia.incendio => 'Incendio',
      };

  IconData get icono => switch (this) {
        TipoIncidencia.calle_cortada => Icons.block,
        TipoIncidencia.zona_terremoto => Icons.waves,
        TipoIncidencia.inundacion => Icons.water,
        TipoIncidencia.incendio => Icons.local_fire_department,
      };

  Color get color => switch (this) {
        TipoIncidencia.calle_cortada => const Color(0xFFD32F2F),
        TipoIncidencia.zona_terremoto => const Color(0xFF8D6E63),
        TipoIncidencia.inundacion => const Color(0xFF1976D2),
        TipoIncidencia.incendio => const Color(0xFFF57C00),
      };

  GeometriaZona get geometria => switch (this) {
        TipoIncidencia.calle_cortada => GeometriaZona.linea,
        TipoIncidencia.zona_terremoto => GeometriaZona.circulo,
        TipoIncidencia.inundacion => GeometriaZona.poligono,
        TipoIncidencia.incendio => GeometriaZona.circulo,
      };

  /// Consejos básicos de seguridad para cada tipo de incidencia.
  List<String> get consejos => switch (this) {
        TipoIncidencia.calle_cortada => const [
            'No intentes atravesar el corte ni retirar las vallas.',
            'Busca una ruta alternativa y evita la zona.',
            'Deja libre el paso a los vehículos de emergencia.',
            'Sigue las indicaciones de policía y protección civil.',
          ],
        TipoIncidencia.zona_terremoto => const [
            'Durante el temblor: agáchate, cúbrete y agárrate bajo una mesa resistente.',
            'Aléjate de ventanas, estanterías y objetos que puedan caer.',
            'No uses ascensores. Sal con calma cuando termine el temblor.',
            'Espera réplicas y no entres en edificios dañados.',
            'Si hueles a gas, no enciendas luces ni fuego y sal al exterior.',
          ],
        TipoIncidencia.inundacion => const [
            'Sube a zonas altas y no bajes a sótanos ni garajes.',
            'No cruces calles inundadas a pie ni en coche: 30 cm de agua pueden arrastrar un vehículo.',
            'Si el agua entra en casa, desconecta la electricidad y el gas.',
            'Aléjate de ríos, barrancos y alcantarillas.',
            'Sigue las instrucciones de las autoridades y ten una radio a mano.',
          ],
        TipoIncidencia.incendio => const [
            'Aléjate en dirección contraria al viento y al humo.',
            'Cubre nariz y boca con un paño húmedo.',
            'Si hay humo, desplázate agachado: el aire limpio está abajo.',
            'Cierra puertas y ventanas al salir para frenar el fuego.',
            'Llama al 112 e indica tu ubicación exacta.',
          ],
      };

  /// Instrucción para dibujar la zona en el mapa.
  String get instruccionesZona => switch (geometria) {
        GeometriaZona.linea =>
          'Toca el mapa para marcar el inicio y el fin del tramo cortado.',
        GeometriaZona.circulo =>
          'Toca el mapa para marcar el centro y ajusta el radio afectado.',
        GeometriaZona.poligono =>
          'Toca el mapa para marcar los vértices de la zona (mínimo 3).',
      };
}
