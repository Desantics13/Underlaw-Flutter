import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/core/widgets/ul_button.dart';
import 'package:underlaw_flutter/features/insights/state/insights_model.dart';
import 'package:underlaw_flutter/features/insights/widgets/charts/grafica_widget.dart';

/// Sección "Gráficas": visualizaciones de UNA predicción, que conservan su
/// referencia (la pregunta, los valores y el resultado que las originaron).
class GraficasSection extends StatelessWidget {
  final VoidCallback onIrAPredicciones;

  const GraficasSection({super.key, required this.onIrAPredicciones});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<InsightsModel>();
    if (m.idPrediccionGraficas == null) {
      return _SinSeleccion(onIrAPredicciones: onIrAPredicciones);
    }
    if (m.cargandoGraficas) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.gold,
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (m.errorGraficas != null || m.graficas == null) {
      return _Aviso(
        mensaje: m.errorGraficas ?? 'No hay gráficas para mostrar.',
        boton: 'Volver a predecir',
        onTap: onIrAPredicciones,
      );
    }
    final referencia = m.graficas!['referencia'] as Map<String, dynamic>;
    final graficas = (m.graficas!['graficas'] as List)
        .cast<Map<String, dynamic>>();
    final otras = m.resultados.values
        .where((r) => r['id_prediccion'] != referencia['id_prediccion'])
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Referencia(referencia: referencia),
        if (otras.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in otras)
                ActionChip(
                  avatar: const Icon(
                    Symbols.swap_horiz,
                    size: 16,
                    color: AppColors.gold,
                  ),
                  label: Text('Ver: ${r['titulo']}'),
                  labelStyle: GoogleFonts.jost(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () => context.read<InsightsModel>().verGraficas(
                    r['id_prediccion'] as String,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        for (var i = 0; i < graficas.length; i++) ...[
          GraficaWidget(
                key: ValueKey(
                  '${referencia['id_prediccion']}-${graficas[i]['id']}',
                ),
                datos: graficas[i],
              )
              .animate()
              .fadeIn(
                duration: 420.ms,
                delay: (90 * i).ms,
                curve: AppMotion.curve,
              )
              .moveY(
                begin: 16,
                end: 0,
                duration: 420.ms,
                delay: (90 * i).ms,
                curve: AppMotion.curve,
              ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _Referencia extends StatelessWidget {
  final Map<String, dynamic> referencia;

  const _Referencia({required this.referencia});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.goldA10,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.goldA45),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.link, size: 16, color: AppColors.gold),
              const SizedBox(width: 6),
              Text('REFERENCIA DE LA PREDICCIÓN', style: kickerStyle()),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            referencia['pregunta'] as String,
            style: GoogleFonts.jost(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            (referencia['resultado'] as String).toUpperCase(),
            style: serifTitle(size: 24)
                .copyWith(color: AppColors.gold, height: 1.05),
          ),
          const SizedBox(height: 6),
          Text(
            'ID ${referencia['id_prediccion']} · ${referencia['titulo']}',
            style: GoogleFonts.jost(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SinSeleccion extends StatelessWidget {
  final VoidCallback onIrAPredicciones;

  const _SinSeleccion({required this.onIrAPredicciones});

  @override
  Widget build(BuildContext context) {
    return _Aviso(
      icono: Symbols.monitoring,
      titulo: 'AÚN NO HAY GRÁFICAS',
      mensaje:
          'Haz una predicción y pulsa «Ver gráficas»: aquí verás sus visualizaciones '
          'conectadas a la pregunta y al resultado.',
      boton: 'Ir a predicciones',
      onTap: onIrAPredicciones,
    );
  }
}

class _Aviso extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String mensaje;
  final String boton;
  final VoidCallback onTap;

  const _Aviso({
    this.icono = Symbols.error,
    this.titulo = 'SIN GRÁFICAS',
    required this.mensaje,
    required this.boton,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icono, size: 36, weight: 200, color: AppColors.gold),
          const SizedBox(height: 14),
          Text(titulo, style: kickerStyle()),
          const SizedBox(height: 10),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: GoogleFonts.jost(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 240,
            child: UlButton.secondary(label: boton, onPressed: onTap),
          ),
        ],
      ),
    );
  }
}
