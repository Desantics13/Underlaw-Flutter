// En Flutter Web usa JS interop real contra el widget.js de Wompi; en
// cualquier otra plataforma (Android/iOS, todavía sin implementar) lanza un
// error explícito en vez de fallar en tiempo de compilación.
export 'wompi_checkout_stub.dart' if (dart.library.js_interop) 'wompi_checkout_web.dart';
