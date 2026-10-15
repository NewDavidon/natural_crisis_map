import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/incidencia.dart';
import '../models/tipo_incidencia.dart';
import '../widgets/fotos.dart';
import 'definir_zona_screen.dart';

/// Datos de la incidencia que se rellenan antes de marcar la zona en el mapa.
class BorradorIncidencia {
  const BorradorIncidencia({
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.gravedad,
    required this.fotos,
  });

  final TipoIncidencia tipo;
  final String titulo;
  final String descripcion;
  final Gravedad gravedad;
  final List<Uint8List> fotos;
}

/// Paso 1 de 2 para reportar una incidencia: tipo, datos y fotos.
class IncidenciaFormScreen extends StatefulWidget {
  const IncidenciaFormScreen({super.key});

  static const maxFotos = 4;

  @override
  State<IncidenciaFormScreen> createState() => _IncidenciaFormScreenState();
}

class _IncidenciaFormScreenState extends State<IncidenciaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  TipoIncidencia? _tipoSeleccionado;
  Gravedad _gravedad = Gravedad.media;
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<Uint8List> _fotos = [];
  bool _mostrarErrorTipo = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _anadirFoto() async {
    final bytes = await elegirFoto(context);
    if (bytes != null && mounted) setState(() => _fotos.add(bytes));
  }

  void _siguienteEtapa() {
    final formularioOk = _formKey.currentState!.validate();
    setState(() => _mostrarErrorTipo = _tipoSeleccionado == null);
    if (!formularioOk || _tipoSeleccionado == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DefinirZonaScreen(
          borrador: BorradorIncidencia(
            tipo: _tipoSeleccionado!,
            titulo: _tituloCtrl.text.trim(),
            descripcion: _descCtrl.text.trim(),
            gravedad: _gravedad,
            fotos: List.of(_fotos),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva incidencia (1/2)')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Selector de tipo
                Text('¿Qué está pasando? *', style: tema.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tipo in TipoIncidencia.values)
                      ChoiceChip(
                        avatar: Icon(tipo.icono, color: tipo.color),
                        label: Text(tipo.etiqueta),
                        selected: _tipoSeleccionado == tipo,
                        onSelected: (_) => setState(() {
                          _tipoSeleccionado = tipo;
                          _mostrarErrorTipo = false;
                        }),
                      ),
                  ],
                ),
                if (_mostrarErrorTipo)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'Selecciona un tipo de incidencia',
                      style: TextStyle(color: tema.colorScheme.error, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 20),

                // Gravedad
                Text('Gravedad', style: tema.textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<Gravedad>(
                  segments: [
                    for (final g in Gravedad.values)
                      ButtonSegment(
                        value: g,
                        label: Text(g.etiqueta),
                        icon: Icon(Icons.circle, size: 12, color: g.color),
                      ),
                  ],
                  selected: {_gravedad},
                  onSelectionChanged: (s) => setState(() => _gravedad = s.first),
                ),
                const SizedBox(height: 20),

                // Campo Título (obligatorio)
                TextFormField(
                  controller: _tituloCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    hintText: 'Ej.: Calle Mayor inundada',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Obligatorio';
                    }
                    if (v.trim().length < 3) {
                      return 'Mínimo 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Campo Descripción (opcional)
                TextFormField(
                  controller: _descCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    hintText: 'Qué has visto, si hay heridos, accesos cortados…',
                    prefixIcon: Icon(Icons.description),
                  ),
                  minLines: 2,
                  maxLines: 5,
                ),
                const SizedBox(height: 20),

                // Fotos
                Text('Fotos (opcional)', style: tema.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _fotos.length; i++)
                      MiniaturaFoto(
                        bytes: _fotos[i],
                        onBorrar: () => setState(() => _fotos.removeAt(i)),
                      ),
                    if (_fotos.length < IncidenciaFormScreen.maxFotos)
                      SizedBox.square(
                        dimension: 96,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _anadirFoto,
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_a_photo),
                              SizedBox(height: 4),
                              Text('Añadir'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'No te pongas en peligro para hacer una foto.',
                  style: tema.textTheme.bodySmall,
                ),
                const SizedBox(height: 24),

                // Botón "Siguiente"
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _siguienteEtapa,
                    icon: const Icon(Icons.map),
                    label: const Text('Siguiente: marcar la zona en el mapa'),
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
