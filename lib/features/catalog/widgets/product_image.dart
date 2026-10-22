import 'package:flutter/material.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/core/widgets/striped_placeholder.dart';

// Foto de producto: fondo rayado del diseño mientras carga (o si falla) y
// fade-in de la imagen real (`producto.imagen`, BoxFit.cover).
class ProductImage extends StatelessWidget {
  final String? url;
  final double stripe;

  const ProductImage({super.key, required this.url, this.stripe = 10});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        StripedPlaceholder(stripe: stripe),
        if (url != null)
          Image.network(
            url!,
            fit: BoxFit.cover,
            frameBuilder: (_, child, frame, sync) => AnimatedOpacity(
              opacity: sync || frame != null ? 1 : 0,
              duration: AppMotion.base,
              curve: AppMotion.curve,
              child: child,
            ),
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
      ],
    );
  }
}
