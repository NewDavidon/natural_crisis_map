import 'package:flutter/material.dart';

import '../models/punto_ayuda.dart';
import '../services/sesion.dart';
import '../services/ubicacion_service.dart';
import '../utils/formato.dart';
import '../utils/geo.dart';
import 'enlaces.dart';

/// Abre la ficha de un punto de ayuda en una hoja inferior.
Future<void> mostrarDetallePuntoAyuda(
  BuildContext context,
  PuntoAyuda punto, {
  VoidCallback? onVerEnMapa,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => _DetallePuntoAyuda(punto: punto, onVerEnMapa: onVerEnMapa),
  );
}

class _DetallePuntoAyuda extends StatelessWidget {
  const _DetallePuntoAyuda({required this.punto, this.onVerEnMapa});

  final PuntoAyuda punto;
  final VoidCallback? onVerEnMapa;

  Future<void> _borrar(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar punto de ayuda?'),
        content: Text('"${punto.nombre}" dejará de aparecer en el mapa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmado != true) return;
    try {
      await Sesion.instance.repo.borrarPuntoAyuda(punto.id);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Punto de ayuda eliminado')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final posicion = UbicacionService.instance.posicion;
    final telefono = extraerTelefono(punto.contacto);
    final esMio = Sesion.instance.usuario?.uid == punto.userId;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: punto.tipo.color,
                foregroundColor: Colors.white,
                child: Icon(punto.tipo.icono),
              ),
              const SizedBox(width: 12),
              Text(punto.tipo.etiqueta, style: tema.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          Text(punto.nombre, style: tema.textTheme.headlineSmall),
          if (posicion != null) ...[
            const SizedBox(height: 4),
            Text('A ${formatearDistancia(distanciaMetros(posicion, punto.posicion))} de ti'),
          ],
          if (punto.descripcion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(punto.descripcion, style: tema.textTheme.bodyLarge),
          ],
          if (punto.contacto.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(punto.contacto)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Añadido por ${punto.autor.isEmpty ? 'un usuario' : punto.autor} · ${formatearFecha(punto.fecha)}',
            style: tema.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => comoLlegar(
                  context,
                  punto.posicion.latitude,
                  punto.posicion.longitude,
                ),
                icon: const Icon(Icons.directions),
                label: const Text('Cómo llegar'),
              ),
              if (telefono != null)
                FilledButton.tonalIcon(
                  onPressed: () => llamar(context, telefono),
                  icon: const Icon(Icons.call),
                  label: const Text('Llamar'),
                ),
              if (onVerEnMapa != null)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onVerEnMapa!();
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Ver en el mapa'),
                ),
              if (esMio)
                TextButton.icon(
                  onPressed: () => _borrar(context),
                  style: TextButton.styleFrom(foregroundColor: tema.colorScheme.error),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
