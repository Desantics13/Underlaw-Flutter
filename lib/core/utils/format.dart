import 'package:intl/intl.dart';

final _copFormatter = NumberFormat.decimalPattern('es_CO');

String formatCOP(num amount) => '\$${_copFormatter.format(amount)} COP';

const _dias = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];
const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// "viernes 31 de octubre · 8:00 p. m." (hora local del dispositivo).
String formatApertura(DateTime fecha) {
  final f = fecha.toLocal();
  final h12 = f.hour % 12 == 0 ? 12 : f.hour % 12;
  final sufijo = f.hour < 12 ? 'a. m.' : 'p. m.';
  final min = f.minute.toString().padLeft(2, '0');
  return '${_dias[f.weekday - 1]} ${f.day} de ${_meses[f.month - 1]} · $h12:$min $sufijo';
}

/// Igual que [formatCOP] pero sin el sufijo "COP" (para barras con poco ancho).
String formatCOPShort(num amount) => '\$${_copFormatter.format(amount)}';
