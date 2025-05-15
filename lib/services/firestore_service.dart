import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incidencia.dart';

/// Servicio para manejar operaciones CRUD reales en Firestore
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Crear o actualizar una incidencia
  Future<void> saveIncidencia(Incidencia incidencia) async {
    await _db
        .collection('incidencias')
        .doc(incidencia.id)
        .set(incidencia.toMap());
  }

  /// Obtener incidencias en tiempo real
  Stream<List<Incidencia>> getIncidencias() {
    return _db
        .collection('incidencias')
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // Se invierte el orden de los argumentos para coincidir con:
        // Incidencia.fromMap(Map<String, dynamic> map, String docId)
        return Incidencia.fromMap(
          doc.data(),
          doc.id,
        );
      }).toList();
    });
  }

  /// Eliminar una incidencia
  Future<void> deleteIncidencia(String id) async {
    await _db.collection('incidencias').doc(id).delete();
  }
}
