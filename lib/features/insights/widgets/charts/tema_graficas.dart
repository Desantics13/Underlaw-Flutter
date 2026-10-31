import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';

/// Datos de una gráfica tal como llegan de GET /graficas/{id}.
typedef DatosGrafica = Map<String, dynamic>;

/// Paleta y estilos compartidos por todas las gráficas: dorado como acento
/// principal (modelo ganador / dato clave), grises para lo secundario.
class TemaGraficas {
  static const ganador = AppColors.gold;
  static const secundarios = [
    Color(0xCCF2F0EC),
    AppColors.textTertiary,
    Color(0xFF6F6A60),
  ];

  /// Color de la serie de un modelo: el ganador siempre en dorado.
  static Color modelo(int indice, bool esGanador) =>
      esGanador ? ganador : secundarios[indice % secundarios.length];

  static const segmentos = {
    'Premium': AppColors.gold,
    'En riesgo': AppColors.error,
    'Ocasionales': Color(0xFFCFC9BE),
    'Regulares': Color(0xFF7F8A94),
  };

  static Color segmento(String nombre) =>
      segmentos[nombre] ?? AppColors.textTertiary;

  static TextStyle get eje =>
      GoogleFonts.jost(fontSize: 10, color: AppColors.textTertiary);
  static TextStyle get leyenda =>
      GoogleFonts.jost(fontSize: 11, color: AppColors.textSecondary);
  static TextStyle get tooltip =>
      GoogleFonts.jost(fontSize: 11, color: AppColors.textPrimary);
}

/// Contenedor de una gráfica: título, descripción, librería usada y la gráfica.
class GraficaCard extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final String libreria;
  /// Alto fijo de la gráfica; null = el que necesite el contenido.
  final double? altura;
  final Widget child;
  final Widget? accion;

  const GraficaCard({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.libreria,
    required this.child,
    this.altura = 260,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo.toUpperCase(),
                  style: serifTitle(size: 21).copyWith(height: 1.05),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  libreria.toUpperCase(),
                  style: GoogleFonts.jost(
                    fontSize: 8,
                    letterSpacing: 1.6,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            descripcion,
            style: GoogleFonts.jost(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 14),
          if (altura == null) child else SizedBox(height: altura, child: child),
          if (accion != null) ...[const SizedBox(height: 8), accion!],
        ],
      ),
    );
  }
}
