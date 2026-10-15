import 'package:flutter/material.dart';

import '../models/punto_ayuda.dart';
import '../models/tipo_incidencia.dart';
import '../services/ubicacion_service.dart';
import '../utils/formato.dart';
import '../utils/geo.dart';
import '../widgets/enlaces.dart';

/// Teléfono de emergencias o de ayuda.
class _Telefono {
  const _Telefono(this.numero, this.nombre, this.icono, [this.nota]);
  final String numero;
  final String nombre;
  final IconData icono;
  final String? nota;
}

const _telefonos = [
  _Telefono('091', 'Policía Nacional', Icons.local_police),
  _Telefono('062', 'Guardia Civil', Icons.shield),
  _Telefono('080', 'Bomberos', Icons.fire_truck, 'En algunos municipios, llama al 112'),
  _Telefono('061', 'Urgencias sanitarias', Icons.medical_services, 'Según comunidad autónoma'),
  _Telefono('092', 'Policía Local', Icons.local_police_outlined),
];

const _mochilaEmergencia = [
  'Agua: unos 3 litros por persona y día',
  'Comida que no necesite frío ni cocinarse',
  'Linterna y pilas de repuesto',
  'Radio a pilas para seguir las noticias',
  'Botiquín y medicamentos habituales',
  'Batería externa y cargador del móvil',
  'Copia de documentos importantes y algo de efectivo',
  'Ropa de abrigo, manta y un silbato',
];

/// Pestaña de ayuda: emergencias, puntos de ayuda cercanos y consejos.
class AyudaScreen extends StatelessWidget {
  const AyudaScreen({
    super.key,
    required this.puntosAyuda,
    required this.onTapPuntoAyuda,
  });

  final List<PuntoAyuda> puntosAyuda;
  final void Function(PuntoAyuda) onTapPuntoAyuda;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;

    return ListenableBuilder(
      listenable: UbicacionService.instance,
      builder: (context, _) {
        final pos = UbicacionService.instance.posicion;
        final puntos = puntosAyuda
            .map((p) => (punto: p, distancia: pos == null ? null : distanciaMetros(pos, p.posicion)))
            .toList();
        if (pos != null) puntos.sort((a, b) => a.distancia!.compareTo(b.distancia!));

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            // — Emergencias —
            Card(
              color: colores.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Estás en peligro?',
                      style: tema.textTheme.titleLarge?.copyWith(color: colores.onErrorContainer),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'El 112 atiende cualquier emergencia, gratis y las 24 horas, '
                      'también sin saldo ni cobertura de tu operador.',
                      style: TextStyle(color: colores.onErrorContainer),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: colores.error,
                          foregroundColor: colores.onError,
                          textStyle: tema.textTheme.titleMedium,
                        ),
                        onPressed: () => llamar(context, '112'),
                        icon: const Icon(Icons.call),
                        label: const Text('Llamar al 112'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // — Teléfonos útiles —
            const _Seccion('Teléfonos útiles'),
            Card(
              child: Column(
                children: [
                  for (final t in _telefonos)
                    ListTile(
                      leading: Icon(t.icono),
                      title: Text(t.nombre),
                      subtitle: t.nota == null ? null : Text(t.nota!),
                      trailing: FilledButton.tonalIcon(
                        onPressed: () => llamar(context, t.numero),
                        icon: const Icon(Icons.call, size: 18),
                        label: Text(t.numero),
                      ),
                    ),
                ],
              ),
            ),

            // — Puntos de ayuda —
            _Seccion(pos == null ? 'Puntos de ayuda' : 'Puntos de ayuda cercanos'),
            if (puntos.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Todavía no hay puntos de ayuda.'),
                  subtitle: Text('Si conoces un albergue, reparto de agua o puesto sanitario, añádelo.'),
                ),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (final (:punto, :distancia) in puntos)
                      ListTile(
                        onTap: () => onTapPuntoAyuda(punto),
                        leading: CircleAvatar(
                          backgroundColor: punto.tipo.color,
                          foregroundColor: Colors.white,
                          child: Icon(punto.tipo.icono),
                        ),
                        title: Text(punto.nombre),
                        subtitle: Text(
                          [
                            punto.tipo.etiqueta,
                            if (distancia != null) formatearDistancia(distancia),
                          ].join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                  ],
                ),
              ),

            // — Consejos —
            const _Seccion('Qué hacer en cada situación'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final tipo in TipoIncidencia.values)
                    ExpansionTile(
                      leading: Icon(tipo.icono, color: tipo.color),
                      title: Text(tipo.etiqueta),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      children: [for (final c in tipo.consejos) _Punto(c)],
                    ),
                  ExpansionTile(
                    leading: const Icon(Icons.backpack),
                    title: const Text('Mochila de emergencia'),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    children: [for (final c in _mochilaEmergencia) _Punto(c)],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo);
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.check, size: 18),
      title: Text(texto),
    );
  }
}
