import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:underlaw_flutter/app/root_shell.dart';
import 'package:underlaw_flutter/features/cart/state/cart_model.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';

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
