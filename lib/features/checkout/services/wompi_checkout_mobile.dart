// Implementación para Android/iOS: abre el checkout de Wompi en un WebView
// de pantalla completa que carga assets/wompi_checkout.html (esa página es
// la que de verdad llama al widget.js de Wompi, ver ese archivo para el
// detalle). dart:js_interop no existe fuera de Flutter Web, así que acá no
// hay JS interop directo — la comunicación con la página es por
// JavaScriptChannel.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

Future<String?> openWompiCheckout({
  required BuildContext context,
  required String publicKey,
  required String reference,
  required int amountInCents,
  required String currency,
}) {
  return Navigator.of(context).push<String?>(
    MaterialPageRoute(
      builder: (_) => _WompiCheckoutWebView(
        publicKey: publicKey,
        reference: reference,
        amountInCents: amountInCents,
        currency: currency,
      ),
      fullscreenDialog: true,
    ),
  );
}

class _WompiCheckoutWebView extends StatefulWidget {
  final String publicKey;
  final String reference;
  final int amountInCents;
  final String currency;

  const _WompiCheckoutWebView({
    required this.publicKey,
    required this.reference,
    required this.amountInCents,
    required this.currency,
  });

  @override
  State<_WompiCheckoutWebView> createState() => _WompiCheckoutWebViewState();
}

class _WompiCheckoutWebViewState extends State<_WompiCheckoutWebView> {
  late final WebViewController _controller;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'WompiResult',
        onMessageReceived: (message) {
          if (!mounted) return;
          final status = message.message;
          Navigator.of(context).pop(status.isEmpty ? null : status);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() => _cargando = false);
            final configJson = jsonEncode({
              'currency': widget.currency,
              'amountInCents': widget.amountInCents,
              'reference': widget.reference,
              'publicKey': widget.publicKey,
            });
            // abrirCheckout(configJson: string) espera un STRING que ella misma
            // parsea con JSON.parse. jsonEncode(configJson) produce un literal
            // de string de JS ya escapado correctamente (comillas, barras, etc.).
            final jsStringLiteral = jsonEncode(configJson);
            _controller.runJavaScript('abrirCheckout($jsStringLiteral)');
          },
        ),
      )
      ..loadFlutterAsset('assets/wompi_checkout.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago con Wompi')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_cargando) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
