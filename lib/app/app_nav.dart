import 'package:flutter/foundation.dart';

// Pestaña activa del shell (0 Inicio, 1 Colección, 2 Carrito). Las rutas
// empujadas encima (detalle, checkout, resultado) la cambian y hacen
// popUntil(first) para volver al shell en la pestaña correcta.
final ValueNotifier<int> shellTab = ValueNotifier<int>(0);
