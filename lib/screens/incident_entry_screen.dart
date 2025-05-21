// lib/screens/incident_entry_screen.dart

import 'package:flutter/material.dart';
import '../services/pending_incidents_service.dart';

class IncidentEntryScreen extends StatefulWidget {
  const IncidentEntryScreen({Key? key}) : super(key: key);

  @override
  State<IncidentEntryScreen> createState() => _IncidentEntryScreenState();
}

class _IncidentEntryScreenState extends State<IncidentEntryScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _saveIncident() {
    if (!_formKey.currentState!.validate()) return;
    PendingIncidentsService.instance.add(
      titulo: _titleCtrl.text.trim(),
      descripcion: _descCtrl.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Incidencia guardada en borrador')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rellenar incidencia'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveIncident,
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
