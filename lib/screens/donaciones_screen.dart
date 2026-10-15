import 'dart:async';

import 'package:flutter/material.dart';

import '../models/donacion.dart';
import '../services/sesion.dart';
import '../utils/formato.dart';
import '../widgets/enlaces.dart';

/// Organización a la que se puede donar desde su web oficial.
class _Organizacion {
  const _Organizacion(this.nombre, this.descripcion, this.url, this.icono);
  final String nombre;
  final String descripcion;
  final String url;
  final IconData icono;
}

const _organizaciones = [
  _Organizacion('Cruz Roja Española', 'Emergencias y ayuda humanitaria',
      'https://www.cruzroja.es', Icons.add_box),
  _Organizacion('Cáritas Española', 'Atención a personas y familias afectadas',
      'https://www.caritas.es', Icons.favorite),
  _Organizacion('UNICEF España', 'Infancia en situaciones de emergencia',
      'https://www.unicef.es', Icons.child_care),
  _Organizacion('Médicos Sin Fronteras', 'Ayuda médica de emergencia',
      'https://www.msf.es', Icons.medical_services),
  _Organizacion('Bancos de Alimentos (FESBAL)', 'Alimentos para quien lo necesita',
      'https://www.fesbal.org', Icons.shopping_basket),
];

/// Pestaña de donaciones: organizaciones oficiales y tablón solidario
/// donde los vecinos ofrecen o piden ayuda material.
class DonacionesScreen extends StatefulWidget {
  const DonacionesScreen({super.key});

  @override
  State<DonacionesScreen> createState() => _DonacionesScreenState();
}

class _DonacionesScreenState extends State<DonacionesScreen> {
  // Una sola suscripción para toda la pantalla: el tablón está dentro de un
  // ListView que destruye y recrea sus hijos al hacer scroll.
  StreamSubscription<List<Donacion>>? _suscripcion;
  List<Donacion>? _donaciones;
  Object? _error;
  ClaseDonacion? _filtro;
  bool _ocultarCubiertas = true;

  @override
  void initState() {
    super.initState();
    _suscripcion = Sesion.instance.repo.donaciones().listen(
          (lista) => setState(() {
            _donaciones = lista;
            _error = null;
          }),
          onError: (Object e) => setState(() => _error = e),
        );
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }

  Widget _tablon() {
    if (_error != null) {
      return Text('No se pudo cargar el tablón: $_error');
    }
    if (_donaciones == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final lista = _donaciones!
        .where((d) => _filtro == null || d.clase == _filtro)
        .where((d) => !_ocultarCubiertas || !d.cubierta)
        .toList();
    if (lista.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.inbox),
          title: Text('No hay publicaciones todavía.'),
          subtitle: Text('Publica lo que puedes ofrecer o lo que necesitas.'),
        ),
      );
    }
    return Column(
      children: [for (final d in lista) _TarjetaDonacion(donacion: d)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Card(
          color: tema.colorScheme.secondaryContainer,
          child: ListTile(
            leading: Icon(Icons.verified_user, color: tema.colorScheme.onSecondaryContainer),
            title: Text(
              'Dona solo por canales oficiales',
              style: TextStyle(color: tema.colorScheme.onSecondaryContainer),
            ),
            subtitle: Text(
              'Esta app no gestiona pagos. Para donar dinero, entra en la web '
              'oficial de la organización. Desconfía de peticiones por mensaje.',
              style: TextStyle(color: tema.colorScheme.onSecondaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Organizaciones', style: tema.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (final org in _organizaciones)
                ListTile(
                  leading: Icon(org.icono, color: tema.colorScheme.primary),
                  title: Text(org.nombre),
                  subtitle: Text(org.descripcion),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => abrirEnlace(context, Uri.parse(org.url)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Tablón solidario', style: tema.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Vecinos que ofrecen o necesitan material, alojamiento o transporte.',
          style: tema.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        SegmentedButton<ClaseDonacion?>(
          segments: const [
            ButtonSegment(value: null, label: Text('Todo')),
            ButtonSegment(value: ClaseDonacion.ofrezco, label: Text('Se ofrece')),
            ButtonSegment(value: ClaseDonacion.necesito, label: Text('Se necesita')),
          ],
          selected: {_filtro},
          onSelectionChanged: (s) => setState(() => _filtro = s.first),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilterChip(
            label: const Text('Ocultar cubiertas'),
            selected: _ocultarCubiertas,
            onSelected: (v) => setState(() => _ocultarCubiertas = v),
          ),
        ),
        const SizedBox(height: 8),
        _tablon(),
      ],
    );
  }
}

class _TarjetaDonacion extends StatelessWidget {
  const _TarjetaDonacion({required this.donacion});

  final Donacion donacion;

  Future<void> _accion(BuildContext context, String accion) async {
    final repo = Sesion.instance.repo;
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (accion == 'cubierta') {
        await repo.marcarDonacionCubierta(donacion.id, !donacion.cubierta);
      } else if (accion == 'borrar') {
        await repo.borrarDonacion(donacion.id);
        messenger.showSnackBar(const SnackBar(content: Text('Publicación eliminada')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo actualizar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final d = donacion;
    final esMia = Sesion.instance.usuario?.uid == d.userId;
    final telefono = extraerTelefono(d.contacto);

    return Opacity(
      opacity: d.cubierta ? 0.6 : 1,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: d.clase.color.withValues(alpha: 0.15),
                    side: BorderSide(color: d.clase.color),
                    label: Text(d.clase.etiqueta, style: TextStyle(color: d.clase.color)),
                  ),
                  const SizedBox(width: 8),
                  Icon(d.categoria.icono, size: 20),
                  const SizedBox(width: 4),
                  Expanded(child: Text(d.categoria.etiqueta, style: tema.textTheme.titleSmall)),
                  if (d.cubierta)
                    const Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(Icons.check, size: 16),
                      label: Text('Cubierta'),
                    ),
                  if (esMia)
                    PopupMenuButton<String>(
                      tooltip: 'Opciones',
                      onSelected: (a) => _accion(context, a),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'cubierta',
                          child: Text(d.cubierta ? 'Marcar como pendiente' : 'Marcar como cubierta'),
                        ),
                        const PopupMenuItem(value: 'borrar', child: Text('Eliminar')),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(d.descripcion, style: tema.textTheme.bodyLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (d.zona.isNotEmpty)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.place, size: 16),
                      const SizedBox(width: 4),
                      Text(d.zona),
                    ]),
                  if (d.contacto.isNotEmpty)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.contact_phone, size: 16),
                      const SizedBox(width: 4),
                      Flexible(child: Text(d.contacto)),
                    ]),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${d.autor.isEmpty ? 'Usuario' : d.autor} · ${formatearFecha(d.fecha)}',
                      style: tema.textTheme.bodySmall,
                    ),
                  ),
                  if (telefono != null && !d.cubierta)
                    TextButton.icon(
                      onPressed: () => llamar(context, telefono),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Llamar'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
