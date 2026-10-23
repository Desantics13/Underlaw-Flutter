import 'package:flutter/material.dart';
import 'package:underlaw_flutter/app/app_nav.dart';
import 'package:underlaw_flutter/app/floating_nav.dart';
import 'package:underlaw_flutter/features/cart/screens/cart_screen.dart';
import 'package:underlaw_flutter/features/catalog/screens/products_screen.dart';
import 'package:underlaw_flutter/features/home/screens/home_screen.dart';
import 'package:underlaw_flutter/features/insights/screens/insights_screen.dart';

// Shell de la app: IndexedStack con [Inicio, Colección, Carrito, Insights] y la barra
// inferior flotante encima. Insights reúne minería/predicciones y gráficas.
// La barra se oculta en Detalle, Checkout y Resultado porque son rutas
// empujadas encima del shell.
class RootShell extends StatelessWidget {
  const RootShell({super.key});

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
            const InsightsScreen(),
          ],
        ),
        bottomNavigationBar: FloatingNav(
          currentIndex: index,
          onSelect: (i) => shellTab.value = i,
        ),
      ),
    );
  }
}
