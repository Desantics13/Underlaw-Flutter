import 'package:intl/intl.dart';

final _copFormatter = NumberFormat.decimalPattern('es_CO');

String formatCOP(num amount) => '\$${_copFormatter.format(amount)} COP';
