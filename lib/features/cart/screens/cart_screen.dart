import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:underlaw_flutter/app/app_nav.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/core/utils/format.dart';
import 'package:underlaw_flutter/core/widgets/ul_button.dart';
import 'package:underlaw_flutter/core/widgets/ul_stepper.dart';
import 'package:underlaw_flutter/core/widgets/ul_toast.dart';
import 'package:underlaw_flutter/features/cart/models/cart_item.dart';
import 'package:underlaw_flutter/features/cart/state/cart_model.dart';
import 'package:underlaw_flutter/features/catalog/screens/product_detail_screen.dart';
import 'package:underlaw_flutter/features/catalog/widgets/product_image.dart';
import 'package:underlaw_flutter/features/checkout/screens/checkout_screen.dart';

String _piezas(int n) => '$n ${n == 1 ? 'pieza' : 'piezas'}';

// Pestaña Carrito: líneas con swipe para eliminar y resumen siempre visible
// encima de la barra flotante.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    if (cart.items.isEmpty) return const _CarritoVacio();

    final top = math.max(MediaQuery.paddingOf(context).top, 20.0);
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.only(top: top + 24, bottom: 300),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _piezas(cart.cantidadTotal).toUpperCase(),
                    style: kickerStyle(),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'CARRITO',
                    style: serifTitle(size: 44).copyWith(height: 1),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Symbols.swipe_left,
                        size: 16,
                        weight: 300,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Desliza a la izquierda para eliminar',
                        style: GoogleFonts.jost(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            for (final item in cart.items)
              _LineaCarrito(key: ValueKey(item.lineId), item: item),
          ],
        ),
        const Positioned(left: 20, right: 20, bottom: 100, child: _Resumen()),
      ],
    );
  }
}

class _LineaCarrito extends StatelessWidget {
  final CartItem item;
  const _LineaCarrito({super.key, required this.item});

  void _eliminar(BuildContext context) {
    HapticFeedback.mediumImpact();
    context.read<CartModel>().quitar(item.lineId);
    UlToast.show(
      context,
      'Pieza eliminada del carrito',
      icon: Symbols.delete,
      bottom: 104,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = item.producto;
    final meta = [
      if (item.talla != null) 'Talla ${item.talla}',
      if (p.nombreLanzamiento != null && p.nombreLanzamiento!.isNotEmpty)
        p.nombreLanzamiento!,
    ].join(' · ');

    return Slidable(
      key: ValueKey('slide-${item.lineId}'),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 96 / MediaQuery.sizeOf(context).width,
        // Arrastrar mucho elimina directo; poco deja la acción abierta.
        dismissible: DismissiblePane(
          dismissThreshold: 0.4,
          resizeDuration: const Duration(milliseconds: 280),
          onDismissed: () => _eliminar(context),
        ),
        children: [
          CustomSlidableAction(
            onPressed: _eliminar,
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.bgPrimary,
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Symbols.delete, size: 22, weight: 300),
                const SizedBox(height: 6),
                Text(
                  'ELIMINAR',
                  style: GoogleFonts.jost(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      child: Container(
        height: 122,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: AppColors.bgPrimary,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => ProductDetailScreen.abrir(context, p),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.thumb),
                child: SizedBox(
                  width: 72,
                  height: 90,
                  child: ProductImage(url: p.imagen, stripe: 8),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombreProducto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jost(
                          fontSize: 15,
                          height: 1.3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jost(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          formatCOP(item.subtotal),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: precioStyle(size: 15),
                        ),
                      ),
                      UlStepper(
                        compact: true,
                        value: item.cantidad,
                        onDecrement: item.cantidad > 1
                            ? () => context
                                  .read<CartModel>()
                                  .actualizarCantidad(item.lineId, -1)
                            : null,
                        incrementDimmed: item.cantidad >= item.maxCompra,
                        onIncrement: () {
                          if (item.cantidad >= item.maxCompra) {
                            UlToast.show(
                              context,
                              'Máximo ${item.maxCompra} por pedido',
                              icon: Symbols.block,
                            );
                            return;
                          }
                          context.read<CartModel>().actualizarCantidad(
                            item.lineId,
                            1,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Resumen fijo: left/right 20, bottom 100, radio 20, fondo #0B0B0A 94% + blur.
class _Resumen extends StatelessWidget {
  const _Resumen();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Total · ${_piezas(cart.cantidadTotal)}',
                      style: GoogleFonts.jost(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(formatCOP(cart.total), style: precioStyle(size: 20)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              UlButton(
                label: 'Ir a pagar',
                icon: Symbols.arrow_forward,
                iconTrailing: true,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CheckoutScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarritoVacio extends StatelessWidget {
  const _CarritoVacio();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 120),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Symbols.shopping_bag,
                size: 38,
                weight: 200,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'TU CARRITO ESTÁ VACÍO',
              textAlign: TextAlign.center,
              style: serifTitle(size: 30).copyWith(height: 1.05),
            ),
            const SizedBox(height: 14),
            Text(
              'Series cortas, telas pesadas y estampados propios. Cuando se agota un drop, no vuelve.',
              textAlign: TextAlign.center,
              style: GoogleFonts.jost(
                fontSize: 15,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            UlButton(
              label: 'Ver colección',
              onPressed: () => shellTab.value = 1,
            ),
          ],
        ),
      ),
    );
  }
}
