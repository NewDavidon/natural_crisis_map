import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre un enlace externo (web, teléfono…) y avisa si no se puede.
Future<void> abrirEnlace(BuildContext context, Uri uri) async {
  var abierto = false;
  try {
    abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    abierto = false;
  }
  if (!abierto && context.mounted) {
    final destino = uri.scheme == 'tel' ? 'llamar al ${uri.path}' : 'abrir ${uri.host}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo $destino desde este dispositivo.')),
    );
  }
}

/// Llama a un número de teléfono.
Future<void> llamar(BuildContext context, String numero) =>
    abrirEnlace(context, Uri(scheme: 'tel', path: numero.replaceAll(' ', '')));

/// Abre la ruta hasta unas coordenadas en Google Maps.
Future<void> comoLlegar(BuildContext context, double lat, double lng) => abrirEnlace(
      context,
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '$lat,$lng',
      }),
    );

/// Busca un número de teléfono dentro de un texto libre (p. ej. "Tel. 600 123 456").
String? extraerTelefono(String texto) {
  final match = RegExp(r'(\+?\d[\d\s]{7,}\d)').firstMatch(texto);
  return match?.group(1)?.replaceAll(' ', '');
}
