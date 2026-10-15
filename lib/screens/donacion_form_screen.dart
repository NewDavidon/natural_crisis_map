import 'package:flutter/material.dart';

import '../models/donacion.dart';
import '../services/sesion.dart';

/// Publicar en el tablón solidario lo que ofreces o necesitas.
class DonacionFormScreen extends StatefulWidget {
  const DonacionFormScreen({super.key});

  @override
  State<DonacionFormScreen> createState() => _DonacionFormScreenState();
}

class _DonacionFormScreenState extends State<DonacionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _zonaCtrl = TextEditingController();
  final _contactoCtrl = TextEditingController();
  ClaseDonacion _clase = ClaseDonacion.ofrezco;
  CategoriaDonacion _categoria = CategoriaDonacion.agua;
  bool _guardando = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _zonaCtrl.dispose();
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
      await Sesion.instance.repo.crearDonacion(Donacion(
        id: '',
        clase: _clase,
        categoria: _categoria,
        descripcion: _descCtrl.text.trim(),
        zona: _zonaCtrl.text.trim(),
        contacto: _contactoCtrl.text.trim(),
        fecha: DateTime.now(),
        userId: usuario.uid,
        autor: usuario.nombre,
      ));
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Publicado en el tablón solidario')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      messenger.showSnackBar(SnackBar(content: Text('No se pudo publicar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar en el tablón')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<ClaseDonacion>(
                  segments: const [
                    ButtonSegment(
                      value: ClaseDonacion.ofrezco,
                      label: Text('Ofrezco'),
                      icon: Icon(Icons.card_giftcard),
                    ),
                    ButtonSegment(
                      value: ClaseDonacion.necesito,
                      label: Text('Necesito'),
                      icon: Icon(Icons.pan_tool),
                    ),
                  ],
                  selected: {_clase},
                  onSelectionChanged: (s) => setState(() => _clase = s.first),
                ),
                const SizedBox(height: 20),
                Text('Categoría', style: tema.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in CategoriaDonacion.values)
                      ChoiceChip(
                        avatar: Icon(c.icono),
                        label: Text(c.etiqueta),
                        selected: _categoria == c,
                        onSelected: (_) => setState(() => _categoria = c),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: 300,
                  decoration: InputDecoration(
                    labelText: 'Descripción *',
                    hintText: _clase == ClaseDonacion.ofrezco
                        ? 'Ej.: 20 garrafas de agua de 5 litros'
                        : 'Ej.: Pañales y leche infantil para 3 bebés',
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 5 ? 'Describe un poco más (mínimo 5 caracteres)' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _zonaCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Zona o barrio',
                    prefixIcon: Icon(Icons.place),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cómo contactarte',
                    hintText: 'Teléfono, email o punto de recogida',
                    prefixIcon: Icon(Icons.contact_phone),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lo que publiques será visible para todos los usuarios. '
                  'No compartas datos que no quieras hacer públicos.',
                  style: tema.textTheme.bodySmall,
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
                        : const Icon(Icons.send),
                    label: const Text('Publicar'),
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
