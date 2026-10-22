import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/core/utils/format.dart';
import 'package:underlaw_flutter/features/catalog/models/producto.dart';
import 'package:underlaw_flutter/features/catalog/screens/product_detail_screen.dart';
import 'package:underlaw_flutter/features/catalog/widgets/product_image.dart';

// Tarjeta del catálogo: imagen 4:5 (radio 14) → drop → nombre → precio.
// Presionada baja a scale 0.97; si todas las tallas están agotadas muestra el
// badge AGOTADO y el nombre en textTertiary.
class ProductCard extends StatefulWidget {
  final Producto producto;

  const ProductCard({super.key, required this.producto});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _pressed = false;

  bool get _agotado =>
      widget.producto.tallas.isNotEmpty &&
      widget.producto.tallas.every((t) => !t.disponible);

  void _abrirDetalle() {
    HapticFeedback.lightImpact();
    ProductDetailScreen.abrir(context, widget.producto);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _abrirDetalle,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 160),
        curve: AppMotion.curve,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.field),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: ProductDetailScreen.heroTag(p),
                      child: ProductImage(url: p.imagen),
                    ),
                    if (_agotado)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgPrimary.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'AGOTADO',
                            style: GoogleFonts.jost(
                              fontSize: 9,
                              height: 1,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.nombreLanzamiento != null &&
                      p.nombreLanzamiento!.isNotEmpty) ...[
                    Text(
                      p.nombreLanzamiento!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.jost(
                        fontSize: 10,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],
                  Text(
                    p.nombreProducto,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.jost(
                      fontSize: 15,
                      height: 1.3,
                      color: _agotado
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(formatCOP(p.precio), style: precioStyle(size: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
