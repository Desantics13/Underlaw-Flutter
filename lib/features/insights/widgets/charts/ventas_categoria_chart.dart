import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/features/insights/data/datos_demo.dart';
import 'package:underlaw_flutter/features/insights/widgets/chart_card.dart';

// SENCILLA 1 · Barras: unidades vendidas por categoría. La barra tocada se
// resalta en dorado pleno y muestra su valor.
class VentasCategoriaChart extends StatefulWidget {
  const VentasCategoriaChart({super.key});

  @override
  State<VentasCategoriaChart> createState() => _VentasCategoriaChartState();
}

class _VentasCategoriaChartState extends State<VentasCategoriaChart> {
  int? _tocada;

  @override
  Widget build(BuildContext context) {
    const valores = DatosDemo.ventasPorCategoria;
    final maxY =
        ((valores.reduce((a, b) => a > b ? a : b) * 1.2) / 20).ceil() * 20.0;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 40,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 40,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(v.toInt().toString(), style: ChartStyle.eje),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                space: 8,
                child: Text(
                  DatosDemo.categorias[v.toInt()],
                  style: ChartStyle.eje.copyWith(
                    color: v.toInt() == _tocada
                        ? AppColors.gold
                        : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchCallback: (event, resp) {
            final idx = event.isInterestedForInteractions
                ? resp?.spot?.touchedBarGroupIndex
                : null;
            if (idx != _tocada) setState(() => _tocada = idx);
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => ChartStyle.tooltipFondo,
            tooltipBorder: ChartStyle.tooltipBorde,
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
              '${DatosDemo.categorias[gi]}\n',
              ChartStyle.tooltip,
              children: [
                TextSpan(
                  text: '${rod.toY.toInt()} unidades',
                  style: ChartStyle.tooltipDestacado,
                ),
              ],
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < valores.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: valores[i],
                  width: 26,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  color: AppColors.gold.withValues(
                    alpha: _tocada == null || _tocada == i ? 1 : 0.4,
                  ),
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 400),
      curve: AppMotion.curve,
    );
  }
}
