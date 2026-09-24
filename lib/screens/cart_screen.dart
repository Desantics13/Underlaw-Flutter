import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/cart_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: cart.items.isEmpty
          ? const Center(child: Text('Tu carrito está vacío.', style: TextStyle(color: AppColors.textMuted)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              separatorBuilder: (_, _) => const Divider(color: AppColors.border),
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: item.producto.imagen != null
                      ? Image.network(item.producto.imagen!, width: 56, height: 56, fit: BoxFit.cover)
                      : const Icon(Icons.checkroom, color: AppColors.textMuted),
                  title: Text(item.producto.nombreProducto, style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    '${item.talla != null ? 'Talla ${item.talla} · ' : ''}${formatCOP(item.producto.precio)}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
                        onPressed: () => cart.actualizarCantidad(item.lineId, -1),
                      ),
                      Text('${item.cantidad}', style: const TextStyle(color: AppColors.textPrimary)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.textSecondary),
                        onPressed: () => cart.actualizarCantidad(item.lineId, 1),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(color: AppColors.textMuted)),
                        Text(formatCOP(cart.total), style: const TextStyle(color: AppColors.gold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.textPrimary,
                          foregroundColor: AppColors.bgPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                        ),
                        child: const Text('IR A PAGAR'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
