import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/punto_ayuda.dart';
import '../services/sesion.dart';
import '../widgets/mapa_base.dart';

/// Formulario para añadir un punto de ayuda (albergue, agua, sanitario…).
class PuntoAyudaFormScreen extends StatefulWidget {
  const PuntoAyudaFormScreen({super.key, required this.posicionInicial});

  final LatLng posicionInicial;

  @override
  State<PuntoAyudaFormScreen> createState() => _PuntoAyudaFormScreenState();
}

class _PuntoAyudaFormScreenState extends State<PuntoAyudaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contactoCtrl = TextEditingController();
  TipoAyuda _tipo = TipoAyuda.albergue;
  late LatLng _posicion = widget.posicionInicial;
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _contactoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final usuario = Sesion.instance.usuario;
    if (!_formKey.currentState!.validate() || usuario == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _guardando = true);
    try {
      await Sesion.instance.repo.crearPuntoAyuda(PuntoAyuda(
        id: '',
        tipo: _tipo,
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descCtrl.text.trim(),
        contacto: _contactoCtrl.text.trim(),
        posicion: _posicion,
        fecha: DateTime.now(),
        userId: usuario.uid,
        autor: usuario.nombre,
      ));
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Punto de ayuda añadido al mapa')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      messenger.showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo punto de ayuda')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Tipo de ayuda', style: tema.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tipo in TipoAyuda.values)
                      ChoiceChip(
                        avatar: Icon(tipo.icono, color: tipo.color),
                        label: Text(tipo.etiqueta),
                        selected: _tipo == tipo,
                        onSelected: (_) => setState(() => _tipo = tipo),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    hintText: 'Ej.: Polideportivo municipal',
                    prefixIcon: Icon(Icons.place),
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 3 ? 'Mínimo 3 caracteres' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Qué se ofrece',
                    hintText: 'Camas, comida caliente, se admiten mascotas…',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Horario o contacto',
                    hintText: 'Ej.: 24 h · Tel. 600 000 000',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Ubicación', style: tema.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Toca el mapa para mover el punto.', style: tema.textTheme.bodySmall),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 260,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: _posicion,
                        initialZoom: 16,
                        onTap: (_, punto) => setState(() => _posicion = punto),
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        capaOpenStreetMap(),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _posicion,
                              width: 40,
                              height: 40,
                              child: IconoMapa(icono: _tipo.icono, color: _tipo.color, tamano: 40),
                            ),
                          ],
                        ),
                        atribucionOpenStreetMap(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _guardando ? null : _guardar,
                    icon: _guardando
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Guardar punto de ayuda'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
