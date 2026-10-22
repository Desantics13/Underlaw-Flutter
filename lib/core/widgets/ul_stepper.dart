import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';

// Stepper de cantidad. Normal (detalle): alto 48, radio 14, botones de 48×48.
// Compacto (carrito): 36 visibles con área táctil de 44, radio 12.
// Los botones deshabilitados quedan a textPrimary 25%.
class UlStepper extends StatelessWidget {
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool compact;
  // El "+" se ve deshabilitado (25%) pero igual responde (p. ej. con un toast).
  final bool incrementDimmed;

  const UlStepper({
    super.key,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    this.compact = false,
    this.incrementDimmed = false,
  });

  Widget _boton(IconData icon, VoidCallback? onTap, {bool dimmed = false}) {
    final size = compact ? 44.0 : 48.0;
    final habilitado = onTap != null && !dimmed;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          size: compact ? 18 : 20,
          weight: 300,
          color: habilitado
              ? (compact ? AppColors.textSecondary : AppColors.textPrimary)
              : AppColors.textA25,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alto = compact ? 36.0 : 48.0;
    final boton = compact ? 44.0 : 48.0;
    final centro = compact ? 18.0 : 28.0;
    final ancho = boton * 2 + centro + 2; // +2 del borde
    return Container(
      width: ancho,
      height: alto,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 12 : AppRadius.field),
        border: Border.all(color: AppColors.border),
      ),
      // El área táctil (44) es mayor que la caja visible (36) en el compacto.
      child: OverflowBox(
        maxWidth: ancho,
        maxHeight: boton,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _boton(Symbols.remove, onDecrement),
            SizedBox(
              width: centro,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: GoogleFonts.jost(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            _boton(Symbols.add, onIncrement, dimmed: incrementDimmed),
          ],
        ),
      ),
    );
  }
}
