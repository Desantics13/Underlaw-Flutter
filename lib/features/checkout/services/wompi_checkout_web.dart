// Llama al widget.js de Wompi (cargado en web/index.html) vía JS interop,
// igual que src/pages/Products.jsx lo hace en JavaScript puro:
//   new WidgetCheckout({ currency, amountInCents, reference, publicKey }).open(callback)
//
// OJO: el SDK de Wompi NO llama al callback de open() cuando el usuario
// cierra el widget manualmente (X, Esc, "volver al comercio") — en esos
// casos solo le agrega el atributo "hidden" a su propio modal
// (clase .waybox-backdrop) y nunca avisa al integrador. Lo detectamos por
// DOM con un MutationObserver, exactamente igual que hace Products.jsx.
@JS()
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

@JS('WidgetCheckout')
extension type _WidgetCheckout._(JSObject _) implements JSObject {
  external factory _WidgetCheckout(JSAny config);
  external void open(JSFunction callback);
}

Future<String?> openWompiCheckout({
  required BuildContext context,
  required String publicKey,
  required String reference,
  required int amountInCents,
  required String currency,
}) {
  final completer = Completer<String?>();

  final config = {
    'currency': currency,
    'amountInCents': amountInCents,
    'reference': reference,
    'publicKey': publicKey,
  }.jsify()!;

  late final web.MutationObserver observer;

  void handleMutations(
    JSArray<web.MutationRecord> mutations,
    web.MutationObserver obs,
  ) {
    if (completer.isCompleted) return;
    for (final mutation in mutations.toDart) {
      final target = mutation.target;
      if (!target.isA<web.HTMLElement>()) continue;
      final el = target as web.HTMLElement;
      if (el.classList.contains('waybox-backdrop') &&
          el.hasAttribute('hidden')) {
        observer.disconnect();
        completer.complete(
          null,
        ); // cierre manual: sin resultado -> se trata como cancelado
        return;
      }
    }
  }

  observer = web.MutationObserver(handleMutations.toJS);
  observer.observe(
    web.document.body!,
    web.MutationObserverInit(
      subtree: true,
      attributes: true,
      attributeFilter: ['hidden'.toJS].toJS,
    ),
  );

  void handleResult(JSAny? result) {
    if (completer.isCompleted) return;
    observer.disconnect();

    if (result == null) {
      completer.complete(null);
      return;
    }
    final dartResult = result.dartify();
    String? status;
    if (dartResult is Map) {
      final transaction = dartResult['transaction'];
      if (transaction is Map) {
        status = transaction['status'] as String?;
      }
    }
    completer.complete(status);
  }

  _WidgetCheckout(config).open(handleResult.toJS);

  return completer.future;
}
