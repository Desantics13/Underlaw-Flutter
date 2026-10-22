import 'package:underlaw_flutter/features/catalog/models/talla_disponible.dart';

class Producto {
  final int id;
  final String nombreProducto;
  final String? nombreLanzamiento;
  final double precio;
  final String? imagen;
  final String? descripcion;
  final String? detalle;
  final int? seccionId;
  final List<TallaDisponible> tallas;

  Producto({
    required this.id,
    required this.nombreProducto,
    this.nombreLanzamiento,
    required this.precio,
    this.imagen,
    this.descripcion,
    this.detalle,
    this.seccionId,
    this.tallas = const [],
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: (json['id'] as num).toInt(),
      nombreProducto: json['nombre_producto']?.toString() ?? '',
      nombreLanzamiento: json['nombre_lanzamiento']?.toString(),
      precio: double.tryParse(json['precio'].toString()) ?? 0,
      imagen: json['imagen']?.toString(),
      descripcion: json['descripcion']?.toString(),
      detalle: json['detalle']?.toString(),
      seccionId: (json['seccion_id'] as num?)?.toInt(),
      tallas: (json['tallas'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TallaDisponible.fromJson)
          .toList(),
    );
  }
}
