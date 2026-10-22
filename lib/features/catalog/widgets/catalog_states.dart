import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shimmer/shimmer.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/core/widgets/ul_button.dart';

// Skeleton de 4 tarjetas (imagen 4:5 + 3 barras) con shimmer lineal de 1.4 s.
class CatalogSkeleton extends StatelessWidget {
  const CatalogSkeleton({super.key});

  // El shimmer usa el color del hijo solo como máscara: va en blanco.
  Widget _bar(double height, double factor, double radius) =>
      FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: factor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );

  Widget _card() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AspectRatio(
        aspectRatio: 4 / 5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
        ),
      ),
      const SizedBox(height: 12),
      _bar(9, 0.5, 5),
      const SizedBox(height: 12),
      _bar(12, 0.8, 6),
      const SizedBox(height: 12),
      _bar(12, 0.4, 6),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.placeholderA,
      highlightColor: AppColors.shimmerHi,
      period: const Duration(milliseconds: 1400),
      child: Column(
        children: [
          for (var r = 0; r < 2; r++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _card()),
                const SizedBox(width: 12),
                Expanded(child: _card()),
              ],
            ),
            if (r == 0) const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }
}

// Estado de error de la Colección: círculo de 88, kicker, título y REINTENTAR.
class CatalogError extends StatelessWidget {
  final VoidCallback onRetry;
  const CatalogError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Symbols.cloud_off,
              size: 36,
              weight: 200,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 28),
          Text('ERROR DE CONEXIÓN', style: kickerStyle(color: AppColors.error)),
          const SizedBox(height: 14),
          Text(
            'NO PUDIMOS CARGAR LA COLECCIÓN',
            textAlign: TextAlign.center,
            style: serifTitle(size: 28).copyWith(height: 1.05),
          ),
          const SizedBox(height: 14),
          Text(
            'Revisa tu conexión e inténtalo de nuevo.',
            textAlign: TextAlign.center,
            style: GoogleFonts.jost(
              fontSize: 15,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 220,
            child: UlButton.secondary(
              label: 'Reintentar',
              icon: Symbols.refresh,
              onPressed: onRetry,
            ),
          ),
        ],
      ),
    );
  }
}
