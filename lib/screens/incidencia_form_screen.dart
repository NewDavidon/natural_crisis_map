import 'package:flutter/material.dart';
import '../models/tipo_incidencia.dart';
import 'map_calle_cortada_screen.dart';
import 'map_zona_terremoto_screen.dart';
import 'map_inundacion_screen.dart';

class IncidenciaFormScreen extends StatefulWidget {
  const IncidenciaFormScreen({Key? key}) : super(key: key);

  @override
  State<IncidenciaFormScreen> createState() => _IncidenciaFormScreenState();
}

class _IncidenciaFormScreenState extends State<IncidenciaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  TipoIncidencia? _tipoSeleccionado;
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _siguienteEtapa() {
    if (!_formKey.currentState!.validate()) return;
    if (_tipoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un tipo de incidencia')),
      );
      return;
    }

    switch (_tipoSeleccionado!) {
      case TipoIncidencia.calle_cortada:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MapCalleCortadaScreen(
              titulo: _tituloCtrl.text.trim(),
              descripcion: _descCtrl.text.trim(),
            ),
          ),
        );
        break;

      case TipoIncidencia.zona_terremoto:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MapZonaTerremotoScreen(
              titulo: _tituloCtrl.text.trim(),
              descripcion: _descCtrl.text.trim(),
            ),
          ),
        );
        break;

      case TipoIncidencia.inundacion:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MapInundacionScreen(
              titulo: _tituloCtrl.text.trim(),
              descripcion: _descCtrl.text.trim(),
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo informe de incidencia')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Selector de tipo (dropdown)
              DropdownButtonFormField<TipoIncidencia>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de incidencia *',
                ),
                value: _tipoSeleccionado,
                items: TipoIncidencia.values.map((tipo) {
                  String texto;
                  switch (tipo) {
                    case TipoIncidencia.calle_cortada:
                      texto = 'Calle cortada';
                      break;
                    case TipoIncidencia.zona_terremoto:
                      texto = 'Zona terremoto';
                      break;
                    case TipoIncidencia.inundacion:
                      texto = 'Inundación';
                      break;
                  }
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(texto),
                  );
                }).toList(),
                onChanged: (nuevoValor) {
                  setState(() {
                    _tipoSeleccionado = nuevoValor;
                  });
                },
                validator: (_) {
                  if (_tipoSeleccionado == null) {
                    return 'Campo obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Campo Título (obligatorio)
              TextFormField(
                controller: _tituloCtrl,
                decoration: InputDecoration(
                  labelText: 'Título *',
                  prefixIcon: const Icon(Icons.title),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide:
                        BorderSide(color: primaryColor.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
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
              const SizedBox(height: 12),

              // Campo Descripción (opcional)
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: const Icon(Icons.description),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide:
                        BorderSide(color: primaryColor.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Botón “Siguiente”
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _siguienteEtapa,
                  child: _isLoading
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                      : const Text('Siguiente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
