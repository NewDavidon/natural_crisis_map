import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/donacion.dart';
import '../models/foto_incidencia.dart';
import '../models/incidencia.dart';
import '../models/punto_ayuda.dart';
import 'crisis_repository.dart';

/// Implementación de [CrisisRepository] sobre Cloud Firestore.
///
/// Colecciones:
///   • incidencias/{id}            → [Incidencia]
///   • incidencias/{id}/fotos/{id} → [FotoIncidencia]
///   • ayudas/{id}                 → [PuntoAyuda]
///   • donaciones/{id}             → [Donacion]
class FirestoreRepository implements CrisisRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _incidencias => _db.collection('incidencias');
  CollectionReference<Map<String, dynamic>> get _ayudas => _db.collection('ayudas');
  CollectionReference<Map<String, dynamic>> get _donaciones => _db.collection('donaciones');
  CollectionReference<Map<String, dynamic>> _fotos(String incidenciaId) =>
      _incidencias.doc(incidenciaId).collection('fotos');

  /// Convierte los documentos de una consulta ignorando los que estén mal
  /// formados, para que un dato corrupto no rompa toda la lista.
  Stream<List<T>> _escuchar<T>(
    Query<Map<String, dynamic>> query,
    T Function(Map<String, dynamic> data, String id) parse,
  ) {
    return query.snapshots().map((snapshot) {
      final lista = <T>[];
      for (final doc in snapshot.docs) {
        try {
          lista.add(parse(doc.data(), doc.id));
        } catch (e) {
          debugPrint('Documento ${doc.reference.path} ignorado: $e');
        }
      }
      return lista;
    });
  }

  // — Incidencias —

  @override
  Stream<List<Incidencia>> incidencias() =>
      _escuchar(_incidencias.orderBy('fecha', descending: true), Incidencia.fromMap);

  @override
  Future<String> crearIncidencia(Incidencia incidencia) async {
    final ref = await _incidencias.add(incidencia.toMap());
    return ref.id;
  }

  @override
  Future<void> marcarIncidenciaActiva(String id, bool activa) =>
      _incidencias.doc(id).update({'activa': activa});

  @override
  Future<void> borrarIncidencia(String id) async {
    // Firestore no borra subcolecciones automáticamente: primero las fotos.
    final fotos = await _fotos(id).get();
    for (final doc in fotos.docs) {
      await doc.reference.delete();
    }
    await _incidencias.doc(id).delete();
  }

  // — Fotos —

  @override
  Stream<List<FotoIncidencia>> fotos(String incidenciaId) =>
      _escuchar(_fotos(incidenciaId).orderBy('fecha'), FotoIncidencia.fromMap);

  @override
  Future<void> anadirFoto(String incidenciaId, FotoIncidencia foto) =>
      _fotos(incidenciaId).add(foto.toMap());

  // — Puntos de ayuda —

  @override
  Stream<List<PuntoAyuda>> puntosAyuda() =>
      _escuchar(_ayudas.orderBy('fecha', descending: true), PuntoAyuda.fromMap);

  @override
  Future<void> crearPuntoAyuda(PuntoAyuda punto) => _ayudas.add(punto.toMap());

  @override
  Future<void> borrarPuntoAyuda(String id) => _ayudas.doc(id).delete();

  // — Donaciones —

  @override
  Stream<List<Donacion>> donaciones() =>
      _escuchar(_donaciones.orderBy('fecha', descending: true), Donacion.fromMap);

  @override
  Future<void> crearDonacion(Donacion donacion) => _donaciones.add(donacion.toMap());

  @override
  Future<void> marcarDonacionCubierta(String id, bool cubierta) =>
      _donaciones.doc(id).update({'cubierta': cubierta});

  @override
  Future<void> borrarDonacion(String id) => _donaciones.doc(id).delete();
}
