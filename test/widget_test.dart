// Smoke test: la app arranca y muestra el wordmark de la marca en la nav.
// (No llama al backend real: solo verifica que el árbol de widgets construye.)

import 'package:flutter_test/flutter_test.dart';

import 'package:underlaw_flutter/main.dart';

void main() {
  testWidgets('La app arranca y muestra UNDERLAW en la barra de navegación', (WidgetTester tester) async {
    await tester.pumpWidget(const UnderLawApp());
    await tester.pump();

    // Aparece tanto en la nav como en el título del Home (IndexedStack
    // construye ambas pantallas aunque solo una esté visible).
    expect(find.text('UNDERLAW'), findsWidgets);
  });
}
