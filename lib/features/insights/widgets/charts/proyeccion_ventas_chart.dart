import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/features/insights/data/datos_demo.dart';
import 'package:underlaw_flutter/features/insights/widgets/chart_card.dart';

List<FlSpot> _spots(List<double> xs, List<double> ys) => [
  for (var i = 0; i < xs.length; i++) FlSpot(xs[i], ys[i]),
];

// AVANZADA 1 · Líneas: histórico de ventas semanales + proyección con banda
// de confianza (área entre el escenario alto y el bajo) y marcador "HOY".
class ProyeccionVentasChart extends StatelessWidget {
  const ProyeccionVentasChart({super.key});

  static const _transparente = Colors.transparent;

  LineChartBarData _linea(
    List<FlSpot> spots, {
    required Color color,
    double ancho = 2.5,
    bool puntos = false,
    List<int>? punteada,
    BarAreaData? area,
  }) => LineChartBarData(
    spots: spots,
    isCurved: true,
    curveSmoothness: 0.25,
    color: color,
    barWidth: ancho,
    isStrokeCapRound: true,
    dashArray: punteada,
    dotData: FlDotData(
      show: puntos,
      getDotPainter: (s, p, b, i) => FlDotCirclePainter(
        radius: 3.5,
        color: AppColors.bgSecondary,
        strokeColor: color,
        strokeWidth: 2,
      ),
    ),
    belowBarData: area ?? BarAreaData(show: false),
  );

  @override
  Widget build(BuildContext context) {
    final historico = _spots(
      DatosDemo.semanasHistorico,
      DatosDemo.unidadesHistorico,
    );
    final prediccion = _spots(
      DatosDemo.semanasPrediccion,
      DatosDemo.unidadesPrediccion,
    );
    final superior = _spots(
      DatosDemo.semanasPrediccion,
      DatosDemo.bandaSuperior,
    );
    final inferior = _spots(
      DatosDemo.semanasPrediccion,
      DatosDemo.bandaInferior,
    );

    return LineChart(
      LineChartData(
        minX: 1,
        maxX: 12,
        minY: 20,
        maxY: 120,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 20,
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
              interval: 20,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(v.toInt().toString(), style: ChartStyle.eje),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (v, meta) =>
                  v.toInt() % 2 == 1 || v.toInt() == 12
                  ? SideTitleWidget(
                      meta: meta,
                      space: 8,
                      child: Text('S${v.toInt()}', style: ChartStyle.eje),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          verticalLines: [
            VerticalLine(
              x: 8,
              color: AppColors.textTertiary,
              strokeWidth: 1,
              dashArray: [4, 4],
              label: VerticalLineLabel(
                show: true,
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.only(left: 6, top: 2),
                style: ChartStyle.eje.copyWith(
                  letterSpacing: 2,
                  color: AppColors.textSecondary,
                ),
                labelResolver: (_) => 'HOY',
              ),
            ),
          ],
        ),
        // Índices: 0 histórico · 1 predicción · 2 banda alta · 3 banda baja.
        lineBarsData: [
          _linea(
            historico,
            color: AppColors.gold,
            area: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.gold.withValues(alpha: 0.22),
                  AppColors.gold.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          _linea(
            prediccion,
            color: AppColors.textPrimary,
            punteada: [6, 5],
            puntos: true,
          ),
          _linea(superior, color: _transparente, ancho: 0),
          _linea(inferior, color: _transparente, ancho: 0),
        ],
        betweenBarsData: [
          BetweenBarsData(
            fromIndex: 2,
            toIndex: 3,
            color: AppColors.gold.withValues(alpha: 0.14),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => ChartStyle.tooltipFondo,
            tooltipBorder: ChartStyle.tooltipBorde,
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipItems: (spots) => [
              for (final s in spots)
                // Solo histórico (0) y predicción (1); las bandas no muestran tooltip.
                if (s.barIndex > 1)
                  null
                else
                  LineTooltipItem(
                    'Semana ${s.x.toInt()}\n',
                    ChartStyle.tooltip,
                    children: [
                      TextSpan(
                        text:
                            '${s.y.toInt()} uds${s.barIndex == 1 ? ' (predicción)' : ''}',
                        style: ChartStyle.tooltipDestacado,
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ),
      duration: const Duration(milliseconds: 500),
      curve: AppMotion.curve,
    );
  }
}

class ProyeccionLeyenda extends StatelessWidget {
  const ProyeccionLeyenda({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        const LeyendaItem(color: AppColors.gold, texto: 'Histórico'),
        const LeyendaItem(
          color: AppColors.textPrimary,
          texto: 'Predicción',
          punteada: true,
        ),
        LeyendaItem(
          color: AppColors.gold.withValues(alpha: 0.4),
          texto: 'Banda de confianza',
        ),
      ],
    );
  }
}
