import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:underlaw_flutter/app/app_nav.dart';
import 'package:underlaw_flutter/app/floating_nav.dart';
import 'package:underlaw_flutter/core/widgets/ul_toast.dart';
import 'package:underlaw_flutter/features/cart/screens/cart_screen.dart';
import 'package:underlaw_flutter/features/catalog/screens/products_screen.dart';
import 'package:underlaw_flutter/features/home/screens/home_screen.dart';

// Shell de la app: IndexedStack con [Inicio, Colección, Carrito] y la barra
// inferior flotante encima. Insights está reservada: por ahora solo avisa.
// La barra se oculta en Detalle, Checkout y Resultado porque son rutas
// empujadas encima del shell.
class RootShell extends StatelessWidget {
  const RootShell({super.key});

  void _goTo(BuildContext context, int index) {
    if (index == 3) {
      UlToast.show(context, 'Insights llegará pronto', icon: Symbols.insights);
      return;
    }
    shellTab.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: shellTab,
      builder: (context, index, _) => Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: index,
          children: [
            HomeScreen(onVerColeccion: () => shellTab.value = 1),
            const ProductsScreen(),
            const CartScreen(),
          ],
        ),
        bottomNavigationBar: FloatingNav(
          currentIndex: index,
          onSelect: (i) => _goTo(context, i),
        ),
      ),
    );
  }
}
