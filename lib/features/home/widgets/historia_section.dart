import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';

// Réplica de la sección #historia de Home.jsx: mismo texto y misma tabla
// (tela, corte, serie, envío), en tarjeta de radio 20.
class HistoriaSection extends StatelessWidget {
  const HistoriaSection({super.key});

  static const _filas = [
    ['Tela', 'Algodón 240 gsm'],
    ['Corte', 'Oversized unisex'],
    ['Serie', '50 por drop'],
    ['Envío', '2 a 5 días hábiles'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LA MARCA', style: kickerStyle()),
          const SizedBox(height: 16),
          Text(
            'POCAS PIEZAS.\nHECHAS BIEN.',
            style: serifTitle(size: 34).copyWith(height: 1),
          ),
          const SizedBox(height: 16),
          Text(
            'UnderLaw nació en Cartagena, Colombia en el 2026 estampando tiradas de '
            '50 camisetas. Seguimos igual: series cortas, telas pesadas y estampados '
            'propios. Cuando se agota un drop, no vuelve.',
            style: GoogleFonts.jost(
              fontSize: 15,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _filas.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: i == _filas.length - 1
                          ? null
                          : const Border(
                              bottom: BorderSide(color: AppColors.border),
                            ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _filas[i][0],
                          style: GoogleFonts.jost(
                            fontSize: 13,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        Text(
                          _filas[i][1],
                          style: GoogleFonts.jost(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
