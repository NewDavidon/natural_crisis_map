import 'package:flutter/material.dart';

import '../models/incidencia.dart';
import '../models/tipo_incidencia.dart';
import '../services/ubicacion_service.dart';
import '../utils/formato.dart';
import '../utils/geo.dart';

/// Pestaña con la lista de incidencias, ordenadas por cercanía.
class IncidenciasListScreen extends StatefulWidget {
  const IncidenciasListScreen({
    super.key,
    required this.incidencias,
    required this.onTapIncidencia,
  });

  final List<Incidencia> incidencias;
  final void Function(Incidencia) onTapIncidencia;

  @override
  State<IncidenciasListScreen> createState() => _IncidenciasListScreenState();
}

class _IncidenciasListScreenState extends State<IncidenciasListScreen> {
  TipoIncidencia? _filtroTipo;
  bool _verResueltas = false;

  @override
  Widget build(BuildContext context) {
    final ubicacion = UbicacionService.instance;

    return ListenableBuilder(
      listenable: ubicacion,
      builder: (context, _) {
        final pos = ubicacion.posicion;
        final lista = widget.incidencias
            .where((i) => _verResueltas || i.activa)
            .where((i) => _filtroTipo == null || i.tipo == _filtroTipo)
            .map((i) => (inc: i, distancia: pos == null ? null : distanciaAIncidencia(pos, i)))
            .toList();
        // Con ubicación: las más cercanas primero. Sin ella: las más recientes.
        if (pos != null) {
          lista.sort((a, b) => a.distancia!.compareTo(b.distancia!));
        }

        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: _filtroTipo == null,
                    onSelected: (_) => setState(() => _filtroTipo = null),
                  ),
                  for (final tipo in TipoIncidencia.values) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: Icon(tipo.icono, size: 18, color: tipo.color),
                      label: Text(tipo.etiqueta),
                      selected: _filtroTipo == tipo,
                      onSelected: (_) => setState(() => _filtroTipo = tipo),
                    ),
                  ],
                  const SizedBox(width: 16),
                  FilterChip(
                    label: const Text('Ver resueltas'),
                    selected: _verResueltas,
                    onSelected: (v) => setState(() => _verResueltas = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: lista.isEmpty
                  ? const _SinIncidencias()
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: lista.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, i) {
                        final (:inc, :distancia) = lista[i];
                        final partes = [
                          if (distancia != null)
                            distancia == 0 ? 'Estás dentro' : 'A ${formatearDistancia(distancia)}',
                          formatearFecha(inc.fecha),
                          if (!inc.activa) 'Resuelta',
                        ];
                        return ListTile(
                          onTap: () => widget.onTapIncidencia(inc),
                          leading: CircleAvatar(
                            backgroundColor: inc.activa ? inc.tipo.color : Colors.grey,
                            foregroundColor: Colors.white,
                            child: Icon(inc.tipo.icono),
                          ),
                          title: Text(inc.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${inc.tipo.etiqueta} · Gravedad ${inc.gravedad.etiqueta.toLowerCase()}\n'
                            '${partes.join(' · ')}',
                          ),
                          isThreeLine: true,
                          trailing: Icon(Icons.circle, size: 12, color: inc.gravedad.color),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SinIncidencias extends StatelessWidget {
  const _SinIncidencias();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text('No hay incidencias que mostrar.', textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text(
              'Si ves algún peligro, repórtalo con el botón "Reportar".',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
