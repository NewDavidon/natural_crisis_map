import 'package:flutter/material.dart';

import '../services/alertas_service.dart';
import '../services/sesion.dart';
import '../services/ubicacion_service.dart';
import '../utils/formato.dart';

/// Hoja inferior para configurar las alertas de cercanía.
/// [onCambio] se llama tras cada cambio para recalcular las alertas.
Future<void> mostrarAjustesAlertas(BuildContext context, {required VoidCallback onCambio}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => _AjustesAlertas(onCambio: onCambio),
  );
}

class _AjustesAlertas extends StatelessWidget {
  const _AjustesAlertas({required this.onCambio});

  final VoidCallback onCambio;

  @override
  Widget build(BuildContext context) {
    final alertas = AlertasService.instance;
    final ubicacion = UbicacionService.instance;
    final tema = Theme.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([alertas, ubicacion]),
      builder: (context, _) {
        final String estadoUbicacion;
        if (ubicacion.esSimulada) {
          estadoUbicacion = 'Ubicación simulada (modo demo)';
        } else if (ubicacion.posicion != null) {
          estadoUbicacion = 'Ubicación activa';
        } else if (ubicacion.cargando) {
          estadoUbicacion = 'Buscando tu ubicación…';
        } else {
          estadoUbicacion = ubicacion.error ?? 'Ubicación no disponible';
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Alertas de cercanía', style: tema.textTheme.titleLarge),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Avisarme de incidencias cercanas'),
                  subtitle: const Text('Recibirás un aviso al acercarte a una zona afectada.'),
                  value: alertas.activadas,
                  onChanged: (v) async {
                    await alertas.cambiarAjustes(activadas: v);
                    onCambio();
                  },
                ),
                const SizedBox(height: 8),
                Text('Distancia de aviso', style: tema.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final radio in AlertasService.radiosDisponibles)
                      ChoiceChip(
                        label: Text(formatearDistancia(radio)),
                        selected: alertas.radioMetros == radio,
                        onSelected: alertas.activadas
                            ? (_) async {
                                await alertas.cambiarAjustes(radioMetros: radio);
                                onCambio();
                              }
                            : null,
                      ),
                  ],
                ),
                const Divider(height: 32),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(ubicacion.posicion != null ? Icons.location_on : Icons.location_off),
                  title: Text(estadoUbicacion),
                  trailing: ubicacion.esSimulada
                      ? TextButton(
                          onPressed: () => ubicacion.simular(null),
                          child: const Text('Usar la real'),
                        )
                      : (ubicacion.posicion == null && !ubicacion.cargando)
                          ? TextButton(
                              onPressed: ubicacion.iniciar,
                              child: const Text('Reintentar'),
                            )
                          : null,
                ),
                Text(
                  'Las alertas funcionan mientras la app está abierta. '
                  'Tu ubicación no se envía ni se comparte con nadie.',
                  style: tema.textTheme.bodySmall,
                ),
                if (Sesion.instance.esDemo) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Modo demo: mantén pulsado el mapa y elige "Simular que estoy aquí" '
                    'para probar las alertas.',
                    style: tema.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
