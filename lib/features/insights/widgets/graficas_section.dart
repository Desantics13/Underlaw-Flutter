import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/features/insights/widgets/chart_card.dart';
import 'package:underlaw_flutter/features/insights/widgets/charts/proyeccion_ventas_chart.dart';
import 'package:underlaw_flutter/features/insights/widgets/charts/segmentos_scatter_chart.dart';
import 'package:underlaw_flutter/features/insights/widgets/charts/tallas_donut_chart.dart';
import 'package:underlaw_flutter/features/insights/widgets/charts/ventas_categoria_chart.dart';

// Sección "Flutter con gráficas": 2 gráficas sencillas y 2 avanzadas con datos
// de ejemplo. Más adelante reaccionarán a los resultados de las predicciones.
class GraficasSection extends StatelessWidget {
  const GraficasSection({super.key});

  Widget _entrada(Widget child, int i) => child
      .animate()
      .fadeIn(duration: 420.ms, delay: (80 * i).ms, curve: AppMotion.curve)
      .moveY(
        begin: 16,
        end: 0,
        duration: 420.ms,
        delay: (80 * i).ms,
        curve: AppMotion.curve,
      );

  @override
  Widget build(BuildContext context) {
    final tarjetas = <Widget>[
      const ChartCard(
        nivel: NivelGrafica.sencilla,
        titulo: 'Ventas por categoría',
        descripcion: 'Unidades vendidas en el último drop. Toca una barra para ver su valor.',
        chart: VentasCategoriaChart(),
      ),
      const ChartCard(
        nivel: NivelGrafica.sencilla,
        titulo: 'Ventas por talla',
        descripcion: 'Qué tallas se llevan la mayor parte de la demanda. Toca un sector.',
        altura: 200,
        chart: TallasDonutChart(),
        leyenda: TallasLeyenda(),
      ),
      const ChartCard(
        nivel: NivelGrafica.avanzada,
        titulo: 'Proyección de ventas',
        descripcion: 'Histórico semanal y predicción a 4 semanas con su banda de confianza.',
        altura: 240,
        chart: ProyeccionVentasChart(),
        leyenda: ProyeccionLeyenda(),
      ),
      const ChartCard(
        nivel: NivelGrafica.avanzada,
        titulo: 'Segmentación de clientes',
        descripcion: 'Clientes agrupados por frecuencia de compra y ticket promedio (clustering).',
        altura: 280,
        chart: SegmentosScatterChart(),
        leyenda: SegmentosLeyenda(),
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < tarjetas.length; i++) ...[
          _entrada(tarjetas[i], i),
          if (i < tarjetas.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}
