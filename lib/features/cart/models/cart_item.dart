import 'package:underlaw_flutter/features/catalog/models/producto.dart';

// Igual que en Products.jsx: la "línea" del carrito se identifica por
// producto + talla (el mismo producto en dos tallas son dos líneas distintas).
class CartItem {
  final Producto producto;
  final String? talla;
  int cantidad;

  CartItem({required this.producto, this.talla, this.cantidad = 1});

  String get lineId => '${producto.id}-${talla ?? 'unica'}';

  double get subtotal => producto.precio * cantidad;

  int get maxCompra {
    if (talla == null) return 10;
    final t = producto.tallas.where((x) => x.talla == talla);
    if (t.isEmpty) return 10;
    return t.first.maxCompra;
  }
}
