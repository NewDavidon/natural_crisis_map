/// Enum que representa los posibles tipos de incidencia
enum TipoIncidencia {
  calle_cortada,
  zona_terremoto,
  inundacion,
}

/// Función auxiliar para convertir un string a TipoIncidencia.
/// Útil para parsing si lees desde JSON / Firestore.
TipoIncidencia tipoFromString(String value) {
  switch (value) {
    case 'calle_cortada':
      return TipoIncidencia.calle_cortada;
    case 'zona_terremoto':
      return TipoIncidencia.zona_terremoto;
    case 'inundacion':
      return TipoIncidencia.inundacion;
    default:
      // En caso de un valor desconocido, devolvemos uno por defecto
      return TipoIncidencia.calle_cortada;
  }
}

/// Función auxiliar para convertir un TipoIncidencia a string.
/// Útil para toMap() o para persistir en Firestore como cadena.
String tipoToString(TipoIncidencia tipo) {
  return tipo.toString().split('.').last;
}
