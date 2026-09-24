import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/products_screen.dart';
import 'state/cart_model.dart';
import 'theme/app_theme.dart';
import 'widgets/top_nav.dart';

void main() {
  runApp(const UnderLawApp());
}

class UnderLawApp extends StatelessWidget {
  const UnderLawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartModel(),
      child: MaterialApp(
        title: 'Under Law',
        debugShowCheckedModeBanner: false,
        theme: buildUnderLawTheme(),
        home: const RootShell(),
      ),
    );
  }
}

// Réplica mínima de la navegación del sitio (Home / Colección), consumiendo
// el mismo backend real (Express + MySQL en Railway) que usa la web.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _currentIndex = 0;

  void _goTo(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNav(currentIndex: _currentIndex, onSelect: _goTo),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(onVerColeccion: () => _goTo(1)),
          const ProductsScreen(),
        ],
      ),
    );
  }
}
