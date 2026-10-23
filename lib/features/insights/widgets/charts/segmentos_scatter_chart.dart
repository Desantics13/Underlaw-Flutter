import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/features/insights/data/datos_demo.dart';
import 'package:underlaw_flutter/features/insights/widgets/chart_card.dart';

// Un tono por segmento (sin colores nuevos): oro para el más valioso.
const _colores = [
  AppColors.textTertiary,
  AppColors.textPrimary,
  AppColors.gold,
];

// AVANZADA 2 · Dispersión: segmentación de clientes (clusters tipo K-means)
// por compras al año (x) y ticket promedio (y). Cada punto es un cliente.
class SegmentosScatterChart extends StatelessWidget {
  const SegmentosScatterChart({super.key});

  @override
  Widget build(BuildContext context) {
    final grupos = DatosDemo.puntosSegmentos();
    final spots = <ScatterSpot>[
      for (var g = 0; g < grupos.length; g++)
        for (final p in grupos[g])
          ScatterSpot(
            p.x,
            p.y,
            dotPainter: FlDotCirclePainter(
              radius: 4.5,
              color: _colores[g].withValues(alpha: 0.85),
              strokeWidth: 1,
              strokeColor: AppColors.bgSecondary,
            ),
          ),
    ];

    String nombreDe(ScatterSpot s) {
      final c = (s.dotPainter as FlDotCirclePainter).color;
      for (var g = 0; g < _colores.length; g++) {
        if (_colores[g].withValues(alpha: 0.85) == c) {
          return DatosDemo.segmentos[g].nombre;
        }
      }
      return '';
    }

    return ScatterChart(
      ScatterChartData(
        minX: 0,
        maxX: 24,
        minY: 0,
        maxY: 400,
        scatterSpots: spots,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          horizontalInterval: 100,
          verticalInterval: 6,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.border, strokeWidth: 1),
          getDrawingVerticalLine: (_) =>
              const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            axisNameSize: 18,
            axisNameWidget: Text(
              'Ticket prom. (miles COP)',
              style: ChartStyle.eje,
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 100,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text('${v.toInt()}', style: ChartStyle.eje),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameSize: 20,
            axisNameWidget: Text('Compras al año', style: ChartStyle.eje),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 6,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                space: 6,
                child: Text('${v.toInt()}', style: ChartStyle.eje),
              ),
            ),
          ),
        ),
        scatterTouchData: ScatterTouchData(
          touchTooltipData: ScatterTouchTooltipData(
            getTooltipColor: (_) => ChartStyle.tooltipFondo,
            tooltipBorder: ChartStyle.tooltipBorde,
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipItems: (s) => ScatterTooltipItem(
              '${nombreDe(s)}\n',
              textStyle: ChartStyle.tooltip,
              children: [
                TextSpan(
                  text:
                      '${s.x.toStringAsFixed(0)} compras · \$${s.y.toStringAsFixed(0)}k',
                  style: ChartStyle.tooltipDestacado,
                ),
              ],
            ),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 500),
      curve: AppMotion.curve,
    );
  }
}

class SegmentosLeyenda extends StatelessWidget {
  const SegmentosLeyenda({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        for (var g = 0; g < DatosDemo.segmentos.length; g++)
          LeyendaItem(color: _colores[g], texto: DatosDemo.segmentos[g].nombre),
      ],
    );
  }
}
