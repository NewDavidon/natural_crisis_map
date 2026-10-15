import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/foto_incidencia.dart';

/// Pregunta si usar cámara o galería y devuelve la foto comprimida,
/// o null si el usuario cancela.
Future<Uint8List?> elegirFoto(BuildContext context) async {
  final origen = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Hacer una foto'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (origen == null) return null;

  try {
    // Reducimos tamaño y calidad para que la foto quepa en Firestore.
    final archivo = await ImagePicker().pickImage(
      source: origen,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 60,
    );
    if (archivo == null) return null;
    final bytes = await archivo.readAsBytes();
    if (!FotoIncidencia.cabeEnFirestore(bytes)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La foto es demasiado grande. Prueba con otra.')),
        );
      }
      return null;
    }
    return bytes;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener la foto: $e')),
      );
    }
    return null;
  }
}

/// Miniatura cuadrada que se amplía al tocarla.
class MiniaturaFoto extends StatelessWidget {
  const MiniaturaFoto({super.key, required this.bytes, this.tamano = 96, this.onBorrar});

  final Uint8List bytes;
  final double tamano;
  final VoidCallback? onBorrar;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: tamano,
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: () => verFotoAmpliada(context, bytes),
              borderRadius: BorderRadius.circular(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
              ),
            ),
          ),
          if (onBorrar != null)
            Positioned(
              top: 2,
              right: 2,
              child: IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                tooltip: 'Quitar foto',
                onPressed: onBorrar,
                icon: const Icon(Icons.close),
              ),
            ),
        ],
      ),
    );
  }
}

/// Muestra la foto a pantalla completa con zoom.
void verFotoAmpliada(BuildContext context, Uint8List bytes) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            maxScale: 5,
            child: Center(child: Image.memory(bytes)),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: SafeArea(
            child: IconButton.filled(
              tooltip: 'Cerrar',
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close),
            ),
          ),
        ),
      ],
    ),
  );
}
