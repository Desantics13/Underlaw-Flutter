import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:underlaw_flutter/app/app_nav.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/core/utils/format.dart';
import 'package:underlaw_flutter/core/widgets/ul_button.dart';

// Resultado del pago, pantalla completa y sin barra inferior.
// Éxito: el carrito ya se vació. Cancelado: el carrito se conserva.
class PaymentResultScreen extends StatefulWidget {
  final bool aprobado;
  final String reference;
  final double total;

  const PaymentResultScreen({
    super.key,
    required this.aprobado,
    required this.reference,
    required this.total,
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.aprobado) HapticFeedback.heavyImpact();
  }

  void _volver(int tab) {
    shellTab.value = tab;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final ok = widget.aprobado;
    final color = ok ? AppColors.success : AppColors.error;
    final filas = <(String, String, Color)>[
      ('Referencia', widget.reference, AppColors.textPrimary),
      ok
          ? ('Total pagado', formatCOP(widget.total), AppColors.gold)
          : (
              'Tu carrito',
              'Sigue guardado · ${formatCOP(widget.total)}',
              AppColors.textSecondary,
            ),
    ];

    return PopScope(
      // El carrito ya está resuelto: evita volver atrás a un checkout viejo.
      canPop: !ok,
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 180),
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
                        border: Border.all(
                          color: color.withValues(alpha: 0.47),
                        ),
                      ),
                      child: Icon(
                        ok ? Symbols.check : Symbols.close,
                        size: 40,
                        weight: 200,
                        color: color,
                      ),
                    ).animate().scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1, 1),
                      delay: 120.ms,
                      duration: 420.ms,
                      curve: AppMotion.curve,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      ok ? 'PEDIDO CONFIRMADO' : 'PAGO CANCELADO',
                      style: kickerStyle(color: color),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      ok ? 'PAGO APROBADO' : 'PAGO NO COMPLETADO',
                      textAlign: TextAlign.center,
                      style: serifTitle(size: 38).copyWith(height: 1),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ok
                          ? 'Te enviamos la factura por correo. ¡Gracias por tu compra!'
                          : 'El pago fue rechazado o cancelado. Puedes intentarlo de nuevo.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jost(
                        fontSize: 15,
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < filas.length; i++)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                border: i == filas.length - 1
                                    ? null
                                    : const Border(
                                        bottom: BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    filas[i].$1,
                                    style: GoogleFonts.jost(
                                      fontSize: 13,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      filas[i].$2,
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.jost(
                                        fontSize: 13,
                                        color: filas[i].$3,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
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
              ),
            ).animate().fadeIn(duration: 400.ms, curve: AppMotion.curve),
            Positioned(
              left: 20,
              right: 20,
              bottom: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UlButton(
                    label: ok ? 'Volver al inicio' : 'Reintentar',
                    onPressed: ok
                        ? () => _volver(0)
                        : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 4),
                  UlButton.tertiary(
                    label: ok
                        ? 'Seguir viendo la colección'
                        : 'Volver al carrito',
                    expand: true,
                    onPressed: () => _volver(ok ? 1 : 2),
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
