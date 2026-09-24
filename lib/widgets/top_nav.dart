import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/cart_screen.dart';
import '../state/cart_model.dart';
import '../theme/app_theme.dart';

// Réplica simple de src/components/Navbar.jsx: logo + wordmark a la
// izquierda, pills de navegación + carrito a la derecha.
class TopNav extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const TopNav({super.key, required this.currentIndex, required this.onSelect});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final cantidad = context.watch<CartModel>().cantidadTotal;

    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text('UNDERLAW', style: serifTitle(size: 20, weight: FontWeight.w400)),
          const Spacer(),
          _NavPill(label: 'Home', selected: currentIndex == 0, onTap: () => onSelect(0)),
          const SizedBox(width: 10),
          _NavPill(label: 'Colección', selected: currentIndex == 1, onTap: () => onSelect(1)),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())),
            icon: Badge(
              label: Text('$cantidad'),
              isLabelVisible: cantidad > 0,
              backgroundColor: AppColors.gold,
              textColor: AppColors.bgPrimary,
              child: const Icon(Icons.shopping_bag_outlined, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: selected ? AppColors.textPrimary : Colors.transparent,
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.bgPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
