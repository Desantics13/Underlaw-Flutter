import 'dart:math' as math;

// Datos de EJEMPLO para la entrega parcial. Más adelante se reemplazan por los
// resultados reales de las predicciones en Python (MySQL → pandas → modelo).
// Mientras tanto, todas las gráficas leen de aquí.
class DatosDemo {
  // ── Sencilla 1: unidades vendidas por categoría (último drop) ──────────
  static const categorias = [
    'Camisetas',
    'Hoodies',
    'Pantalones',
    'Gorras',
    'Accesorios',
  ];
  static const ventasPorCategoria = [128.0, 86.0, 54.0, 71.0, 39.0];

  // ── Sencilla 2: distribución de ventas por talla (%) ───────────────────
  static const tallas = ['S', 'M', 'L', 'XL'];
  static const ventasPorTalla = [18.0, 34.0, 31.0, 17.0];

  // ── Avanzada 1: ventas semanales + proyección con banda de confianza ──
  // Semanas 1–8 son histórico real (ejemplo); 8–12 es la predicción.
  static const List<double> semanasHistorico = [1.0, 2, 3, 4, 5, 6, 7, 8];
  static const List<double> unidadesHistorico = [
    42.0,
    48,
    45,
    57,
    63,
    60,
    72,
    78,
  ];
  static const List<double> semanasPrediccion = [8.0, 9, 10, 11, 12];
  static const List<double> unidadesPrediccion = [78.0, 84, 89, 95, 98];
  static const List<double> bandaSuperior = [78.0, 91, 100, 109, 116];
  static const List<double> bandaInferior = [78.0, 77, 78, 81, 80];

  // ── Avanzada 2: segmentación de clientes (clusters tipo K-means) ──────
  // x = compras al año · y = ticket promedio en miles de COP.
  static const segmentos = [
    Segmento('Ocasionales', cx: 3, cy: 70, sx: 1.2, sy: 20, n: 22),
    Segmento('Frecuentes', cx: 14, cy: 130, sx: 3, sy: 28, n: 24),
    Segmento('Premium', cx: 7, cy: 300, sx: 2, sy: 45, n: 14),
  ];

  /// Puntos reproducibles (semilla fija) para cada segmento.
  static List<List<({double x, double y})>> puntosSegmentos() {
    final rnd = math.Random(7);
    double gauss() {
      final u1 = 1 - rnd.nextDouble();
      final u2 = rnd.nextDouble();
      return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
    }

    return [
      for (final s in segmentos)
        [
          for (var i = 0; i < s.n; i++)
            (
              x: (s.cx + gauss() * s.sx).clamp(0.5, 23.5),
              y: (s.cy + gauss() * s.sy).clamp(15.0, 395.0),
            ),
        ],
    ];
  }
}

class Segmento {
  final String nombre;
  final double cx;
  final double cy;
  final double sx;
  final double sy;
  final int n;

  const Segmento(
    this.nombre, {
    required this.cx,
    required this.cy,
    required this.sx,
    required this.sy,
    required this.n,
  });
}
