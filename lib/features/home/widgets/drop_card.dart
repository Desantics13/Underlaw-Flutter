import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/core/utils/format.dart';
import 'package:underlaw_flutter/core/widgets/ul_button.dart';
import 'package:underlaw_flutter/features/home/models/lanzamiento_activo.dart';

// Tarjeta del drop: kicker + pill de estado, nombre, precio y cuenta regresiva
// (o el botón principal si el drop ya está disponible).
class DropCard extends StatelessWidget {
  final bool cargando;
  final String? error;
  final LanzamientoActivo? lanzamiento;
  final Duration? restante;
  final VoidCallback onVerColeccion;
  final VoidCallback onReintentar;

  const DropCard({
    super.key,
    required this.cargando,
    required this.error,
    required this.lanzamiento,
    required this.restante,
    required this.onVerColeccion,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: _contenido(),
    );
  }

  Widget _contenido() {
    if (cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold,
            ),
          ),
        ),
      );
    }
    if (error != null) {
      return Column(
        children: [
          Text(
            'No pudimos cargar el lanzamiento.',
            style: GoogleFonts.jost(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          UlButton.tertiary(label: 'Reintentar', onPressed: onReintentar),
        ],
      );
    }
    final l = lanzamiento;
    if (l == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No hay ningún lanzamiento activo ahora mismo.',
          style: GoogleFonts.jost(fontSize: 14, color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                l.nombreLanzamiento.toUpperCase(),
                style: kickerStyle(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.goldA45),
              ),
              child: Text(
                l.estaProgramado ? 'PROGRAMADO' : 'YA DISPONIBLE',
                style: GoogleFonts.jost(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                  color: AppColors.gold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(l.nombreProducto.toUpperCase(), style: serifTitle(size: 34)),
        const SizedBox(height: 10),
        Text(
          formatCOP(l.precio),
          style: GoogleFonts.jost(fontSize: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        if (l.estaProgramado) ...[
          _Cronometro(
            restante:
                restante ??
                l.fechaLanzamiento.difference(DateTime.now().toUtc()),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Text(
              'Abre el ${formatApertura(l.fechaLanzamiento)}',
              textAlign: TextAlign.center,
              style: GoogleFonts.jost(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ] else
          UlButton(label: 'Ver colección', onPressed: onVerColeccion),
      ],
    );
  }
}

class _Cronometro extends StatelessWidget {
  final Duration restante;
  const _Cronometro({required this.restante});

  @override
  Widget build(BuildContext context) {
    final total = restante.isNegative ? Duration.zero : restante;
    final celdas = [
      ('${total.inDays}', 'DÍAS'),
      ('${total.inHours % 24}', 'HORAS'),
      ('${total.inMinutes % 60}', 'MIN'),
      ('${total.inSeconds % 60}', 'SEG'),
    ];
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < celdas.length; i++)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(
                            left: BorderSide(color: AppColors.border),
                          ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        celdas[i].$1.padLeft(2, '0'),
                        style: GoogleFonts.jost(
                          fontSize: 30,
                          height: 1,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        celdas[i].$2,
                        style: GoogleFonts.jost(
                          fontSize: 10,
                          height: 1,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
