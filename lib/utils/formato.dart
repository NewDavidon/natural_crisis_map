/// Formatea una distancia en metros: "350 m", "1,2 km".
String formatearDistancia(double metros) {
  if (metros < 1000) return '${metros.round()} m';
  final km = metros / 1000;
  final texto = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
  return '${texto.replaceAll('.', ',')} km';
}

/// Formatea una fecha de forma relativa: "hace 5 min", "hace 3 h"
/// o "15/10/2026 14:30" si es más antigua.
String formatearFecha(DateTime fecha, {DateTime? ahora}) {
  final diff = (ahora ?? DateTime.now()).difference(fecha);
  if (diff.inMinutes < 1) return 'hace un momento';
  if (diff.inHours < 1) return 'hace ${diff.inMinutes} min';
  if (diff.inDays < 1) return 'hace ${diff.inHours} h';
  if (diff.inDays < 7) return 'hace ${diff.inDays} ${diff.inDays == 1 ? 'día' : 'días'}';
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} '
      '${dos(fecha.hour)}:${dos(fecha.minute)}';
}
