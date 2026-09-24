import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/wompi_checkout.dart';
import '../state/cart_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

enum _CheckoutStep { formulario, procesando, aprobado, rechazado }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _telefono = TextEditingController();
  final _correo = TextEditingController();
  final _pais = TextEditingController(text: 'Colombia');
  final _municipio = TextEditingController();
  final _ciudad = TextEditingController();
  final _direccion = TextEditingController();

  _CheckoutStep _step = _CheckoutStep.formulario;
  String? _error;

  @override
  void dispose() {
    for (final c in [_nombre, _apellido, _telefono, _correo, _pais, _municipio, _ciudad, _direccion]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pagar(CartModel cart) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _step = _CheckoutStep.procesando;
      _error = null;
    });

    final formData = {
      'name': _nombre.text.trim(),
      'lastName': _apellido.text.trim(),
      'phone': _telefono.text.trim(),
      'email': _correo.text.trim(),
      'pais': _pais.text.trim(),
      'municipio': _municipio.text.trim(),
      'ciudad': _ciudad.text.trim(),
      'direccion': _direccion.text.trim(),
    };

    final cartPayload = cart.items
        .map((i) => {
              'productId': i.producto.id,
              'name': i.producto.nombreProducto,
              'price': i.producto.precio,
              'quantity': i.cantidad,
              'talla': i.talla,
            })
        .toList();

    try {
      final init = await ApiService.iniciarPago(formData: formData, cart: cartPayload);
      final reference = init['reference'] as String;
      if (!mounted) return;

      final status = await openWompiCheckout(
        context: context,
        publicKey: init['publicKey'] as String,
        reference: reference,
        amountInCents: init['amountInCents'] as int,
        currency: init['currency'] as String,
      );

      if (status == 'APPROVED') {
        await ApiService.confirmarPago(reference);
        cart.vaciar();
        if (!mounted) return;
        setState(() => _step = _CheckoutStep.aprobado);
      } else {
        await ApiService.cancelarPago(reference, status ?? 'VOIDED');
        if (!mounted) return;
        setState(() => _step = _CheckoutStep.rechazado);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _CheckoutStep.formulario;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: switch (_step) {
        _CheckoutStep.procesando => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.gold),
                const SizedBox(height: 24),
                const Text('Completa el pago en la ventana de Wompi…', style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 16),
                // Respaldo manual: si por algún caso raro el widget no avisa que
                // se cerró, esto evita que la pantalla se quede colgada.
                TextButton(
                  onPressed: () => setState(() => _step = _CheckoutStep.formulario),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        _CheckoutStep.aprobado => _buildResultado(
            icono: Icons.check_circle,
            color: AppColors.success,
            titulo: 'Pago aprobado',
            texto: 'Te enviamos la factura por correo. ¡Gracias por tu compra!',
          ),
        _CheckoutStep.rechazado => _buildResultado(
            icono: Icons.cancel,
            color: AppColors.error,
            titulo: 'Pago no completado',
            texto: 'El pago fue rechazado o cancelado. Puedes intentarlo de nuevo.',
            onReintentar: () => setState(() => _step = _CheckoutStep.formulario),
          ),
        _CheckoutStep.formulario => _buildFormulario(cart),
      },
    );
  }

  Widget _buildResultado({
    required IconData icono,
    required Color color,
    required String titulo,
    required String texto,
    VoidCallback? onReintentar,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: color, size: 64),
            const SizedBox(height: 16),
            Text(titulo, style: serifTitle(size: 26)),
            const SizedBox(height: 8),
            Text(texto, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (onReintentar != null) OutlinedButton(onPressed: onReintentar, child: const Text('Reintentar')),
            if (onReintentar == null)
              OutlinedButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text('Volver al inicio')),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulario(CartModel cart) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Total: ${formatCOP(cart.total)}', style: const TextStyle(color: AppColors.gold, fontSize: 18)),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 12),
            ],
            _campo(_nombre, 'Nombre'),
            _campo(_apellido, 'Apellido'),
            _campo(_telefono, 'Teléfono', keyboardType: TextInputType.phone),
            _campo(_correo, 'Correo electrónico', keyboardType: TextInputType.emailAddress),
            _campo(_pais, 'País'),
            _campo(_municipio, 'Departamento/Municipio'),
            _campo(_ciudad, 'Ciudad'),
            _campo(_direccion, 'Dirección'),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.bgPrimary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: const RoundedRectangleBorder(),
              ),
              onPressed: cart.items.isEmpty ? null : () => _pagar(cart),
              child: const Text('PAGAR CON WOMPI'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController controller, String label, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(labelText: label),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
      ),
    );
  }
}
