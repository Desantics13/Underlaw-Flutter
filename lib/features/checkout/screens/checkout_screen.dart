import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:underlaw_flutter/core/api/api_service.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/core/utils/format.dart';
import 'package:underlaw_flutter/core/widgets/ul_button.dart';
import 'package:underlaw_flutter/core/widgets/ul_field.dart';
import 'package:underlaw_flutter/core/widgets/ul_toast.dart';
import 'package:underlaw_flutter/features/cart/models/cart_item.dart';
import 'package:underlaw_flutter/features/cart/state/cart_model.dart';
import 'package:underlaw_flutter/features/checkout/screens/payment_result_screen.dart';
import 'package:underlaw_flutter/features/checkout/services/wompi_checkout.dart';

// Checkout en una sola pantalla: 01 Contacto · 02 Envío · 03 Tu pedido, con
// barra superior y barra de pago fijas. Todos los campos son obligatorios.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _c = {
    'name': TextEditingController(),
    'lastName': TextEditingController(),
    'phone': TextEditingController(),
    'email': TextEditingController(),
    'pais': TextEditingController(text: 'Colombia'),
    'municipio': TextEditingController(),
    'ciudad': TextEditingController(),
    'direccion': TextEditingController(),
  };
  final Map<String, String> _errores = {};
  bool _pagando = false;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Validación al pulsar pagar (igual que el prototipo).
  Map<String, String> _validar() {
    final e = <String, String>{};
    for (final entry in _c.entries) {
      if (entry.value.text.trim().isEmpty) e[entry.key] = 'Requerido';
    }
    final correo = _c['email']!.text.trim();
    if (!e.containsKey('email') &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(correo)) {
      e['email'] = 'Correo no válido';
    }
    final digitos = _c['phone']!.text.replaceAll(RegExp(r'\D'), '');
    if (!e.containsKey('phone') && digitos.length < 7) {
      e['phone'] = 'Teléfono no válido';
    }
    return e;
  }

  Future<void> _pagar(CartModel cart) async {
    final errores = _validar();
    if (errores.isNotEmpty) {
      HapticFeedback.vibrate();
      setState(() {
        _errores
          ..clear()
          ..addAll(errores);
      });
      return;
    }

    setState(() => _pagando = true);

    final formData = {for (final e in _c.entries) e.key: e.value.text.trim()};
    final cartPayload = cart.items
        .map(
          (i) => {
            'productId': i.producto.id,
            'name': i.producto.nombreProducto,
            'price': i.producto.precio,
            'quantity': i.cantidad,
            'talla': i.talla,
          },
        )
        .toList();
    final total = cart.total;

    try {
      final init = await ApiService.iniciarPago(
        formData: formData,
        cart: cartPayload,
      );
      final reference = init['reference'] as String;
      if (!mounted) return;

      final status = await openWompiCheckout(
        context: context,
        publicKey: init['publicKey'] as String,
        reference: reference,
        amountInCents: init['amountInCents'] as int,
        currency: init['currency'] as String,
      );
      if (!mounted) return;

      if (status == 'APPROVED') {
        await ApiService.confirmarPago(reference);
        cart.vaciar();
        if (!mounted) return;
        setState(() => _pagando = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PaymentResultScreen(
              aprobado: true,
              reference: reference,
              total: total,
            ),
          ),
        );
      } else {
        await ApiService.cancelarPago(reference, status ?? 'VOIDED');
        if (!mounted) return;
        setState(() => _pagando = false);
        // El carrito se conserva: "Reintentar" vuelve a esta pantalla.
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PaymentResultScreen(
              aprobado: false,
              reference: reference,
              total: total,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _pagando = false);
      UlToast.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        icon: Symbols.error,
        bottom: 190,
      );
    }
  }

  Widget _campo(String clave, String label, {TextInputType? teclado}) {
    return UlField(
      controller: _c[clave]!,
      label: label,
      keyboardType: teclado,
      error: _errores[clave],
      onChanged: (_) {
        // El error de un campo se borra al escribir en él.
        if (_errores.containsKey(clave)) setState(() => _errores.remove(clave));
      },
    );
  }

  Widget _titulo(String texto, {double arriba = 0}) => Padding(
    padding: EdgeInsets.only(top: arriba, bottom: 14),
    child: Text(texto, style: kickerStyle()),
  );

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final top = math.max(MediaQuery.paddingOf(context).top, 20.0);
    final barraSup = top + 10 + 44 + 10; // padding + botón + padding

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(20, barraSup + 16, 20, 240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _titulo('01 · CONTACTO'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _campo('name', 'Nombre')),
                    const SizedBox(width: 10),
                    Expanded(child: _campo('lastName', 'Apellido')),
                  ],
                ),
                const SizedBox(height: 10),
                _campo('phone', 'Teléfono', teclado: TextInputType.phone),
                const SizedBox(height: 10),
                _campo(
                  'email',
                  'Correo electrónico',
                  teclado: TextInputType.emailAddress,
                ),
                _titulo('02 · ENVÍO', arriba: 36),
                _campo('pais', 'País'),
                const SizedBox(height: 10),
                _campo('municipio', 'Departamento/Municipio'),
                const SizedBox(height: 10),
                _campo('ciudad', 'Ciudad'),
                const SizedBox(height: 10),
                _campo('direccion', 'Dirección'),
                _titulo('03 · TU PEDIDO', arriba: 36),
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
                      for (var i = 0; i < cart.items.length; i++)
                        _LineaPedido(
                          item: cart.items[i],
                          ultima: i == cart.items.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _BarraSuperior(top: top),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BarraPago(
              cart: cart,
              pagando: _pagando,
              onPagar: () => _pagar(cart),
              // Respaldo: si el widget no avisa que se cerró, no se queda colgado.
              onCancelar: () => setState(() => _pagando = false),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineaPedido extends StatelessWidget {
  final CartItem item;
  final bool ultima;

  const _LineaPedido({required this.item, required this.ultima});

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (item.talla != null) 'Talla ${item.talla}',
      if (item.producto.nombreLanzamiento != null &&
          item.producto.nombreLanzamiento!.isNotEmpty)
        item.producto.nombreLanzamiento!,
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: ultima
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.producto.nombreProducto} × ${item.cantidad}',
                  style: GoogleFonts.jost(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: GoogleFonts.jost(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatCOP(item.subtotal),
            style: GoogleFonts.jost(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// Barra superior fija: atrás · CHECKOUT · candado.
class _BarraSuperior extends StatelessWidget {
  final double top;
  const _BarraSuperior({required this.top});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, top + 10, 16, 10),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary.withValues(alpha: 0.9),
            border: const Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Symbols.arrow_back,
                    size: 22,
                    weight: 300,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'CHECKOUT',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 22 * 0.12,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(
                width: 44,
                child: Icon(
                  Symbols.lock,
                  size: 20,
                  weight: 300,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Barra inferior fija: total + PAGAR CON WOMPI (cargando: spinner + texto).
class _BarraPago extends StatelessWidget {
  final CartModel cart;
  final bool pagando;
  final VoidCallback onPagar;
  final VoidCallback onCancelar;

  const _BarraPago({
    required this.cart,
    required this.pagando,
    required this.onPagar,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final n = cart.cantidadTotal;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, math.max(30, inset + 12)),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary.withValues(alpha: 0.92),
            border: const Border(top: BorderSide(color: AppColors.border)),
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
                      'Total · $n ${n == 1 ? 'pieza' : 'piezas'}',
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
                label: 'Pagar con Wompi',
                loading: pagando,
                loadingLabel: 'Conectando con Wompi',
                onPressed: cart.items.isEmpty ? null : onPagar,
              ),
              const SizedBox(height: 10),
              if (pagando)
                UlButton.tertiary(label: 'Cancelar', onPressed: onCancelar)
              else
                Text(
                  'Tarjeta, PSE y Nequi · Pago seguro con Wompi',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jost(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
