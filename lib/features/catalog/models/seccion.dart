class Seccion {
  final int id;
  final String nombre;
  final int orden;

  Seccion({required this.id, required this.nombre, required this.orden});

  factory Seccion.fromJson(Map<String, dynamic> json) {
    return Seccion(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? '',
      orden: (json['orden'] as num?)?.toInt() ?? 0,
    );
  }
}
