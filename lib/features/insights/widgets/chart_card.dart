import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';

enum NivelGrafica { sencilla, avanzada }

// Tarjeta contenedora de una gráfica: radio 20, fondo #0B0B0A, borde al 12%.
// Muestra el nivel (sencilla / avanzada), título, descripción, la gráfica y
// una nota de que son datos de ejemplo.
class ChartCard extends StatelessWidget {
  final NivelGrafica nivel;
  final String titulo;
  final String descripcion;
  final double altura;
  final Widget chart;
  final Widget? leyenda;

  const ChartCard({
    super.key,
    required this.nivel,
    required this.titulo,
    required this.descripcion,
    required this.chart,
    this.altura = 220,
    this.leyenda,
  });

  @override
  Widget build(BuildContext context) {
    final avanzada = nivel == NivelGrafica.avanzada;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                avanzada ? 'GRÁFICA AVANZADA' : 'GRÁFICA SENCILLA',
                style: kickerStyle(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: avanzada ? AppColors.goldA10 : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: avanzada ? AppColors.goldA45 : AppColors.border,
                  ),
                ),
                child: Text(
                  avanzada ? 'AVANZADA' : 'SENCILLA',
                  style: GoogleFonts.jost(
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                    color: avanzada ? AppColors.gold : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            titulo.toUpperCase(),
            style: serifTitle(size: 26).copyWith(height: 1.05),
          ),
          const SizedBox(height: 8),
          Text(
            descripcion,
            style: GoogleFonts.jost(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(height: altura, child: chart),
          if (leyenda != null) ...[const SizedBox(height: 16), leyenda!],
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.science_outlined,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                'Datos de ejemplo · simulación',
                style: GoogleFonts.jost(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Estilos compartidos por todas las gráficas: ejes en textTertiary, grillas al 12%.
class ChartStyle {
  static TextStyle get eje =>
      GoogleFonts.jost(fontSize: 10, color: AppColors.textTertiary);

  static TextStyle get tooltip =>
      GoogleFonts.jost(fontSize: 12, height: 1.4, color: AppColors.textPrimary);

  static TextStyle get tooltipDestacado => GoogleFonts.jost(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.gold,
  );

  static const Color tooltipFondo = AppColors.bgPrimary;
  static const BorderSide tooltipBorde = BorderSide(color: AppColors.border);
}

// Fila de leyenda: punto de color + texto.
class LeyendaItem extends StatelessWidget {
  final Color color;
  final String texto;
  final bool punteada;

  const LeyendaItem({
    super.key,
    required this.color,
    required this.texto,
    this.punteada = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        punteada
            ? SizedBox(
                width: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(width: 4, height: 2, color: color),
                  ],
                ),
              )
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
        const SizedBox(width: 8),
        Text(
          texto,
          style: GoogleFonts.jost(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
