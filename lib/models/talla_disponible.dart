// Tal como lo devuelve el backend público: nunca la cantidad real en stock,
// solo si se puede comprar y el tope máximo por compra (ver
// Producto.sanitizarTallasPublicas en el backend).
class TallaDisponible {
  final String talla;
  final bool disponible;
  final int maxCompra;

  TallaDisponible({
    required this.talla,
    required this.disponible,
    required this.maxCompra,
  });

  factory TallaDisponible.fromJson(Map<String, dynamic> json) {
    return TallaDisponible(
      talla: json['talla']?.toString() ?? '',
      disponible: json['disponible'] == true,
      maxCompra: (json['max_compra'] as num?)?.toInt() ?? 10,
    );
  }
}
