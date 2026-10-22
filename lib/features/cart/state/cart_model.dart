import 'package:flutter/foundation.dart';
import 'package:underlaw_flutter/features/cart/models/cart_item.dart';
import 'package:underlaw_flutter/features/catalog/models/producto.dart';

class CartModel extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get cantidadTotal => _items.fold(0, (acc, i) => acc + i.cantidad);

  double get total => _items.fold(0, (acc, i) => acc + i.subtotal);

  void agregar(Producto producto, {String? talla, int cantidad = 1}) {
    final lineId = '${producto.id}-${talla ?? 'unica'}';
    final existente = _items.where((i) => i.lineId == lineId);
    if (existente.isNotEmpty) {
      final item = existente.first;
      item.cantidad = (item.cantidad + cantidad).clamp(1, item.maxCompra);
    } else {
      _items.add(
        CartItem(
          producto: producto,
          talla: talla,
          cantidad: cantidad.clamp(1, 10),
        ),
      );
    }
    notifyListeners();
  }

  void actualizarCantidad(String lineId, int delta) {
    CartItem? item;
    for (final i in _items) {
      if (i.lineId == lineId) {
        item = i;
        break;
      }
    }
    if (item == null) return;
    final nueva = item.cantidad + delta;
    if (nueva <= 0) {
      _items.removeWhere((i) => i.lineId == lineId);
    } else {
      item.cantidad = nueva.clamp(1, item.maxCompra);
    }
    notifyListeners();
  }

  void quitar(String lineId) {
    _items.removeWhere((i) => i.lineId == lineId);
    notifyListeners();
  }

  void vaciar() {
    _items.clear();
    notifyListeners();
  }
}
