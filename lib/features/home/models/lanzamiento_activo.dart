// El lanzamiento (drop) activo que muestra el Home, tal como responde
// GET /api/lanzamientos/home. estado: 'programado' (con cronómetro) o
// 'lanzado' (ya comprable, con producto_id apuntando al catálogo real).
class LanzamientoActivo {
  final int id;
  final String nombreLanzamiento;
  final String nombreProducto;
  final double precio;
  final List<String> imagenes;
  final DateTime fechaLanzamiento;
  final String estado;
  final int? productoId;

  LanzamientoActivo({
    required this.id,
    required this.nombreLanzamiento,
    required this.nombreProducto,
    required this.precio,
    required this.imagenes,
    required this.fechaLanzamiento,
    required this.estado,
    this.productoId,
  });

  bool get estaProgramado => estado == 'programado';
  bool get estaLanzado => estado == 'lanzado';

  factory LanzamientoActivo.fromJson(Map<String, dynamic> json) {
    final imgs = (json['imagenes'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((i) => i['url']?.toString())
        .whereType<String>()
        .toList();

    return LanzamientoActivo(
      id: (json['id'] as num).toInt(),
      nombreLanzamiento: json['nombre_lanzamiento']?.toString() ?? '',
      nombreProducto: json['nombre_producto']?.toString() ?? '',
      precio: double.tryParse(json['precio'].toString()) ?? 0,
      imagenes: imgs,
      // El backend guarda y devuelve la fecha en UTC.
      fechaLanzamiento: DateTime.parse(json['fecha_lanzamiento'].toString())
          .toUtc(),
      estado: json['estado']?.toString() ?? 'programado',
      productoId: (json['producto_id'] as num?)?.toInt(),
    );
  }
}
