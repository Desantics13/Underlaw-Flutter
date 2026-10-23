import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/core/widgets/ul_button.dart';

class _Prediccion {
  final String numero;
  final String pregunta;
  final String resultado;
  final String detalle;
  final double confianza;

  const _Prediccion(
    this.numero,
    this.pregunta,
    this.resultado,
    this.detalle,
    this.confianza,
  );
}

// Predicciones de EJEMPLO. Más adelante cada una será el resultado de un modelo
// en Python (MySQL → pandas → modelo) y moverá las gráficas de la otra sección.
const _predicciones = [
  _Prediccion(
    'PREDICCIÓN 01',
    '¿Cuántas unidades se venderán en las próximas 4 semanas?',
    '≈ 366 unidades',
    'Tendencia al alza: +26% frente al último mes.',
    0.87,
  ),
  _Prediccion(
    'PREDICCIÓN 02',
    '¿Qué talla se agotará primero en el próximo drop?',
    'Talla M · en ~9 días',
    'Concentra el 34% de la demanda histórica.',
    0.81,
  ),
  _Prediccion(
    'PREDICCIÓN 03',
    '¿A qué segmento pertenece un cliente con 12 compras y ticket de \$140k?',
    'Cliente frecuente',
    'Cercano al centro del grupo "Frecuentes".',
    0.92,
  ),
];

// Sección "Minería y predicciones" (simulación): muestra el flujo de datos y
// tres predicciones de ejemplo, cada una con salto directo a las gráficas.
class MineriaSection extends StatelessWidget {
  final VoidCallback onVerGraficas;

  const MineriaSection({super.key, required this.onVerGraficas});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Flujo(),
        const SizedBox(height: 16),
        for (var i = 0; i < _predicciones.length; i++) ...[
          _TarjetaPrediccion(p: _predicciones[i], onVerGraficas: onVerGraficas),
          if (i < _predicciones.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _Flujo extends StatelessWidget {
  static const _pasos = [
    (Symbols.database, 'MySQL'),
    (Symbols.code, 'Python'),
    (Symbols.query_stats, 'Predicción'),
    (Symbols.bar_chart, 'Gráficas'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FLUJO DE DATOS', style: kickerStyle()),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < _pasos.length; i++) ...[
                Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == _pasos.length - 1
                            ? AppColors.goldA10
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: i == _pasos.length - 1
                              ? AppColors.goldA45
                              : AppColors.border,
                        ),
                      ),
                      child: Icon(
                        _pasos[i].$1,
                        size: 22,
                        weight: 300,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _pasos[i].$2.toUpperCase(),
                      style: GoogleFonts.jost(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.4,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                if (i < _pasos.length - 1)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 22),
                    child: Icon(
                      Symbols.arrow_forward,
                      size: 16,
                      weight: 300,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Cada predicción saldrá de un modelo en Python entrenado con los datos de la tienda y moverá las gráficas de la otra sección. Por ahora los resultados son de ejemplo.',
            style: GoogleFonts.jost(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPrediccion extends StatelessWidget {
  final _Prediccion p;
  final VoidCallback onVerGraficas;

  const _TarjetaPrediccion({required this.p, required this.onVerGraficas});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              Text(p.numero, style: kickerStyle()),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'SIMULADO',
                  style: GoogleFonts.jost(
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            p.pregunta,
            style: GoogleFonts.jost(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  p.resultado.toUpperCase(),
                  style: serifTitle(size: 28)
                      .copyWith(height: 1.05, color: AppColors.gold),
                ),
                const SizedBox(height: 8),
                Text(
                  p.detalle,
                  style: GoogleFonts.jost(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Confianza',
                style: GoogleFonts.jost(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: p.confianza,
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(p.confianza * 100).round()}%',
                style: precioStyle(size: 13),
              ),
            ],
          ),
          const SizedBox(height: 18),
          UlButton.secondary(
            label: 'Ver en gráficas',
            icon: Symbols.bar_chart,
            onPressed: onVerGraficas,
          ),
        ],
      ),
    );
  }
}
