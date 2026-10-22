// En Flutter Web usa JS interop real contra el widget.js de Wompi; en
// Android/iOS usa un WebView (dart:js_interop no existe fuera de la web).
export 'wompi_checkout_mobile.dart'
    if (dart.library.js_interop) 'wompi_checkout_web.dart';
