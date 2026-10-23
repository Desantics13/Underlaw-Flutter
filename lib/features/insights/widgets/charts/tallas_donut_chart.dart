import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/features/insights/data/datos_demo.dart';
import 'package:underlaw_flutter/features/insights/widgets/chart_card.dart';

// Tonos del dorado (sin colores nuevos): de pleno a tenue.
const _tonos = [1.0, 0.72, 0.48, 0.28];

Color tonoTalla(int i) => AppColors.gold.withValues(alpha: _tonos[i]);

// SENCILLA 2 · Dona: distribución de ventas por talla. Al tocar un sector
// crece y el centro muestra su porcentaje.
class TallasDonutChart extends StatefulWidget {
  const TallasDonutChart({super.key});

  @override
  State<TallasDonutChart> createState() => _TallasDonutChartState();
}

class _TallasDonutChartState extends State<TallasDonutChart> {
  int? _tocado;

  @override
  Widget build(BuildContext context) {
    const valores = DatosDemo.ventasPorTalla;
    final total = valores.fold<double>(0, (a, b) => a + b);
    final i = _tocado;

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 58,
            startDegreeOffset: -90,
            borderData: FlBorderData(show: false),
            pieTouchData: PieTouchData(
              touchCallback: (event, resp) {
                final idx = event.isInterestedForInteractions
                    ? resp?.touchedSection?.touchedSectionIndex
                    : null;
                final nuevo = (idx == null || idx < 0) ? null : idx;
                if (nuevo != _tocado) setState(() => _tocado = nuevo);
              },
            ),
            sections: [
              for (var k = 0; k < valores.length; k++)
                PieChartSectionData(
                  value: valores[k],
                  color: tonoTalla(k),
                  radius: _tocado == k ? 34 : 28,
                  showTitle: false,
                ),
            ],
          ),
          duration: const Duration(milliseconds: 300),
          curve: AppMotion.curve,
        ),
        IgnorePointer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                i == null
                    ? '${valores.length}'
                    : '${(valores[i] / total * 100).round()}%',
                style: GoogleFonts.jost(
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                i == null ? 'TALLAS' : 'TALLA ${DatosDemo.tallas[i]}',
                style: GoogleFonts.jost(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Leyenda de la dona: talla + porcentaje.
class TallasLeyenda extends StatelessWidget {
  const TallasLeyenda({super.key});

  @override
  Widget build(BuildContext context) {
    const valores = DatosDemo.ventasPorTalla;
    final total = valores.fold<double>(0, (a, b) => a + b);
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        for (var k = 0; k < valores.length; k++)
          LeyendaItem(
            color: tonoTalla(k),
            texto:
                '${DatosDemo.tallas[k]} · ${(valores[k] / total * 100).round()}%',
          ),
      ],
    );
  }
}
