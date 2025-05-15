import 'package:flutter/material.dart';
import '../services/incidencias_service.dart';
import '../models/incidencia.dart';

/// Pantalla principal que muestra un listado de incidencias
class HomeScreen extends StatelessWidget {
  // Eliminado 'const' para poder inicializar _service en tiempo de ejecución
  HomeScreen({Key? key}) : super(key: key);

  // Instancia del servicio de incidencias
  final IncidenciasService _service = IncidenciasService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listado de Incidencias')),
      body: StreamBuilder<List<Incidencia>>(
        // Escucha el stream de incidencias (mock)
        stream: _service.obtenerIncidencias(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final inc = list[i];
              return ListTile(
                title: Text(inc.titulo),
                subtitle: Text(inc.descripcion),
                trailing: Text('${inc.fecha.day}/${inc.fecha.month}/${inc.fecha.year}'),
              );
            },
          );
        },
      ),
    );
  }
}
