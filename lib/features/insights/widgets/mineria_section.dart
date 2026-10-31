import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/core/widgets/ul_button.dart';
import 'package:underlaw_flutter/features/insights/data/ml_api.dart';
import 'package:underlaw_flutter/features/insights/models/prediccion_def.dart';
import 'package:underlaw_flutter/features/insights/state/insights_model.dart';
import 'package:underlaw_flutter/features/insights/util/etiquetas.dart';
import 'package:underlaw_flutter/features/insights/widgets/oracion_prediccion.dart';

/// Sección "Minería y predicciones": una tarjeta por oración. PREDECIR ejecuta
/// el modelo en el servicio de Python y muestra la respuesta.
class MineriaSection extends StatelessWidget {
  final void Function(String idPrediccion) onVerGraficas;

  const MineriaSection({super.key, required this.onVerGraficas});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<InsightsModel>();
    if (m.estado == EstadoCarga.cargando) {
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
    if (m.estado == EstadoCarga.error) {
      return _SinServicio(mensaje: m.error ?? '', onReintentar: m.cargar);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EstadoModelos(salud: m.salud ?? {}),
        const SizedBox(height: 16),
        for (var i = 0; i < m.catalogo.length; i++) ...[
          _TarjetaPrediccion(
                numero: i + 1,
                def: m.catalogo[i],
                onVerGraficas: onVerGraficas,
              )
              .animate()
              .fadeIn(
                duration: 420.ms,
                delay: (80 * i).ms,
                curve: AppMotion.curve,
              )
              .moveY(
                begin: 16,
                end: 0,
                duration: 420.ms,
                delay: (80 * i).ms,
                curve: AppMotion.curve,
              ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _EstadoModelos extends StatelessWidget {
  final Map<String, dynamic> salud;

  const _EstadoModelos({required this.salud});

  @override
  Widget build(BuildContext context) {
    final fuente = (salud['fuente_entrenamiento'] ?? '')
        .toString()
        .toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Servicio de predicción conectado · modelos entrenados el ${salud['modelos_entrenados'] ?? '—'} '
              'desde $fuente con datos sintéticos hasta el ${salud['fecha_corte_datos'] ?? '—'}.',
              style: GoogleFonts.jost(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPrediccion extends StatelessWidget {
  final int numero;
  final PrediccionDef def;
  final void Function(String idPrediccion) onVerGraficas;

  const _TarjetaPrediccion({
    required this.numero,
    required this.def,
    required this.onVerGraficas,
  });

  @override
  Widget build(BuildContext context) {
    final m = context.watch<InsightsModel>();
    final cargando = m.prediciendo[def.id] ?? false;
    final resultado = m.resultados[def.id];
    final error = m.errores[def.id];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: resultado != null ? AppColors.goldA45 : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PREDICCIÓN 0$numero · ${def.tipoProblema.toUpperCase()}',
            style: kickerStyle(),
          ),
          const SizedBox(height: 10),
          Text(
            def.titulo.toUpperCase(),
            style: serifTitle(size: 24).copyWith(height: 1.05),
          ),
          const SizedBox(height: 14),
          OracionPrediccion(
            def: def,
            valores: m.valores[def.id]!,
            habilitada: !cargando,
            onCambio: (campo, valor) => context
                .read<InsightsModel>()
                .cambiarValor(def.id, campo, valor),
          ),
          const SizedBox(height: 6),
          Text(
            'Toca los valores dorados para cambiarlos.',
            style: GoogleFonts.jost(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          UlButton(
            label: 'Predecir',
            icon: Symbols.neurology,
            loading: cargando,
            loadingLabel: 'Ejecutando modelo',
            onPressed: () => context.read<InsightsModel>().predecir(def.id),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error,
              style: GoogleFonts.jost(fontSize: 13, color: AppColors.error),
            ),
          ],
          AnimatedSize(
            duration: AppMotion.base,
            curve: AppMotion.curve,
            alignment: Alignment.topCenter,
            child: resultado == null
                ? const SizedBox(width: double.infinity)
                : _Resultado(
                    resultado: resultado,
                    onVerGraficas: onVerGraficas,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Resultado extends StatelessWidget {
  final Map<String, dynamic> resultado;
  final void Function(String idPrediccion) onVerGraficas;

  const _Resultado({required this.resultado, required this.onVerGraficas});

  @override
  Widget build(BuildContext context) {
    final res = resultado['resultado'] as Map<String, dynamic>;
    final modelo = resultado['modelo'] as Map<String, dynamic>;
    final metricas = (resultado['metricas'] as Map<String, dynamic>?) ?? {};
    final probabilidad = resultado['probabilidad'] as num?;
    final comparados = (modelo['comparados'] as List<dynamic>)
        .where((n) => n != modelo['nombre'])
        .join(' y ');
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RESULTADO', style: labelStyle()),
                const SizedBox(height: 8),
                Text(
                  res['texto'].toString().toUpperCase(),
                  style: serifTitle(size: 28)
                      .copyWith(color: AppColors.gold, height: 1.05),
                ),
                const SizedBox(height: 8),
                Text(
                  res['detalle'].toString(),
                  style: GoogleFonts.jost(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (probabilidad != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: probabilidad.toDouble()),
                      duration: const Duration(milliseconds: 700),
                      curve: AppMotion.curve,
                      builder: (_, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 5,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.gold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            resultado['explicacion'].toString(),
            style: GoogleFonts.jost(
              fontSize: 13,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'MODELO: ${modelo['nombre'].toString().toUpperCase()}',
            style: labelStyle(color: AppColors.gold),
          ),
          const SizedBox(height: 4),
          Text(
            'Comparado con $comparados · criterio: ${modelo['criterio']}.',
            style: GoogleFonts.jost(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in metricas.entries)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${etiquetaMetrica(e.key)} ',
                          style: GoogleFonts.jost(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        TextSpan(
                          text: valorMetrica(e.key, e.value),
                          style: GoogleFonts.jost(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          UlButton.secondary(
            label: 'Ver gráficas',
            icon: Symbols.monitoring,
            onPressed: () =>
                onVerGraficas(resultado['id_prediccion'] as String),
          ),
        ],
      ),
    );
  }
}

class _SinServicio extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _SinServicio({required this.mensaje, required this.onReintentar});

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
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Symbols.cloud_off,
              size: 30,
              weight: 200,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'SERVICIO NO DISPONIBLE',
            style: kickerStyle(color: AppColors.error),
          ),
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
          if (MlApi.configurado) ...[
            const SizedBox(height: 8),
            Text(
              'Dirección: ${MlApi.baseUrl}',
              textAlign: TextAlign.center,
              style: GoogleFonts.jost(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: 220,
            child: UlButton.secondary(
              label: 'Reintentar',
              icon: Symbols.refresh,
              onPressed: onReintentar,
            ),
          ),
        ],
      ),
    );
  }
}
