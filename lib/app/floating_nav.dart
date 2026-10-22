import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/features/cart/state/cart_model.dart';

class NavDestino {
  final String label;
  final IconData icon;
  const NavDestino(this.label, this.icon);
}

// Barra inferior flotante: left/right 20, bottom 24, alto 64, radio 32,
// fondo #0B0B0A 82% + blur 20 y borde 12%. El indicador (pill gold 12%) se
// desliza entre ítems en 340 ms.
class FloatingNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  static const destinos = [
    NavDestino('Inicio', Symbols.home),
    NavDestino('Colección', Symbols.grid_view),
    NavDestino('Carrito', Symbols.shopping_bag),
    NavDestino('Insights', Symbols.insights),
  ];

  static const double height = 64;
  static const double bottomGap = 24;

  const FloatingNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final n = destinos.length;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        bottomGap + MediaQuery.paddingOf(context).bottom * 0.5,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.nav),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: height,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(AppRadius.nav),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 340),
                  curve: AppMotion.curve,
                  alignment: Alignment(-1 + 2 * currentIndex / (n - 1), 0),
                  child: FractionallySizedBox(
                    widthFactor: 1 / n,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.goldA12,
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < n; i++)
                      Expanded(
                        child: _NavItem(
                          destino: destinos[i],
                          activo: i == currentIndex,
                          badge: i == 2
                              ? context.select<CartModel, int>(
                                  (c) => c.cantidadTotal,
                                )
                              : 0,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onSelect(i);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavDestino destino;
  final bool activo;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.destino,
    required this.activo,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = activo ? AppColors.gold : AppColors.textTertiary;
    return Semantics(
      button: true,
      selected: activo,
      label: destino.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  destino.icon,
                  size: 23,
                  weight: 300,
                  fill: activo ? 1 : 0,
                  color: color,
                ),
                const SizedBox(height: 3),
                Text(
                  destino.label.toUpperCase(),
                  style: GoogleFonts.jost(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.4,
                    color: color,
                  ),
                ),
              ],
            ),
            if (badge > 0)
              Positioned(
                top: 3,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: const Offset(12, 0),
                    child: _Badge(cantidad: badge),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Badge del carrito: pop de escala 0.4 → 1.2 → 1 (260 ms) al cambiar la cantidad.
class _Badge extends StatelessWidget {
  final int cantidad;
  const _Badge({required this.cantidad});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(cantidad),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      builder: (_, t, child) {
        final scale = t < 0.6
            ? 0.4 + (1.2 - 0.4) * (t / 0.6)
            : 1.2 - 0.2 * ((t - 0.6) / 0.4);
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(9),
        ),
        // Row.min: el badge se ajusta al número en vez de expandirse.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$cantidad',
              style: GoogleFonts.jost(
                fontSize: 10,
                height: 18 / 10,
                fontWeight: FontWeight.w600,
                color: AppColors.bgPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
