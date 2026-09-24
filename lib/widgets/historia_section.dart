import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Réplica de la sección #historia de Home.jsx: mismo texto y misma tabla
// (tela, corte, serie, envío).
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LA MARCA', style: kickerStyle()),
          const SizedBox(height: 16),
          Text('Pocas piezas.\nHechas bien.', style: serifTitle(size: 34)),
          const SizedBox(height: 16),
          Text(
            'UnderLaw nació en Cartagena, Colombia en el 2026 estampando tiradas de '
            '50 camisetas. Seguimos igual: series cortas, telas pesadas y estampados '
            'propios. Cuando se agota un drop, no vuelve.',
            style: const TextStyle(color: AppColors.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 28),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                for (final fila in _filas)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(fila[0], style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        Text(fila[1], style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
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
