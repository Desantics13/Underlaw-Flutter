import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';

// Zona rayada del handoff (repeating-linear-gradient 135°) para fotos que aún
// no cargan. Se usa de fondo mientras llega `producto.imagen` o la foto del hero.
class StripedPlaceholder extends StatelessWidget {
  final double stripe;
  final Widget? child;

  const StripedPlaceholder({super.key, this.stripe = 12, this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StripesPainter(stripe),
      child: child ?? const SizedBox.expand(),
    );
  }
}

class _StripesPainter extends CustomPainter {
  final double stripe;
  _StripesPainter(this.stripe);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.placeholderA,
    );
    final paint = Paint()..color = AppColors.placeholderB;
    // Bandas perpendiculares a la dirección (1,1): líneas x + y = constante.
    final step = stripe * math.sqrt2;
    final maxT = size.width + size.height;
    for (var a = step; a < maxT; a += step * 2) {
      final b = a + step;
      canvas.drawPath(
        Path()
          ..moveTo(a, 0)
          ..lineTo(b, 0)
          ..lineTo(0, b)
          ..lineTo(0, a)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripesPainter old) => old.stripe != stripe;
}
