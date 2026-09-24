// Implementación de respaldo para plataformas que no son Flutter Web
// (Android/iOS todavía no tienen esta pieza — se agrega en la fase de la app
// nativa, con un WebView en vez de JS interop).
Future<String?> openWompiCheckout({
  required String publicKey,
  required String reference,
  required int amountInCents,
  required String currency,
}) {
  throw UnsupportedError(
    'El checkout con Wompi solo está implementado para Flutter Web por ahora. '
    'La versión para app nativa se agrega en la fase de Android/iOS (vía WebView).',
  );
}
