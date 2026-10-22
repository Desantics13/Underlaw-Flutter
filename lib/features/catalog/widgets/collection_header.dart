import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';

// Encabezado fijo y colapsable de la Colección. Con t = clamp(scroll / 90):
// el bloque de título pasa de 96 → 52 px, el título de 46 → 26 px, el kicker
// se oculta, el fondo sube de 55% → 95% de opacidad (con blur 18) y aparece
// el borde inferior. Los chips quedan debajo.
class CollectionHeader extends StatelessWidget {
  final ValueListenable<double> offset;
  final double topInset;
  final Widget chips;

  static const double _titleMax = 96;
  static const double _titleMin = 52;
  static const double chipsHeight = 70; // 12 + 44 + 14

  const CollectionHeader({
    super.key,
    required this.offset,
    required this.topInset,
    required this.chips,
  });

  /// Alto del encabezado sin colapsar (para el padding superior del contenido).
  static double maxHeight(double topInset) =>
      topInset + _titleMax + chipsHeight;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: offset,
      builder: (context, s, _) {
        final t = (s / 90).clamp(0.0, 1.0);
        final titleH = lerpDouble(_titleMax, _titleMin, t)!;
        final titleSize = lerpDouble(46, 26, t)!;
        final kickerH = 24 * (1 - t);
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: EdgeInsets.only(top: topInset),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary.withValues(
                  alpha: lerpDouble(0.55, 0.95, t)!,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Color.lerp(Colors.transparent, AppColors.border, t)!,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: titleH,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (kickerH > 0.5)
                            SizedBox(
                              height: kickerH,
                              child: ClipRect(
                                child: Opacity(
                                  opacity: 1 - t,
                                  child: OverflowBox(
                                    alignment: Alignment.topLeft,
                                    maxHeight: 24,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Text(
                                        'DROP 01 · ORIGEN',
                                        style: kickerStyle(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Text(
                            'COLECCIÓN',
                            style: serifTitle(size: titleSize)
                                .copyWith(height: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  chips,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
