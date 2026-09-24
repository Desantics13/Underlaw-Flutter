import 'dart:convert';
import 'package:http/http.dart' as http;

// Mismo backend real (Express + MySQL en Railway) que usa el frontend web en
// producción. Son endpoints públicos de solo lectura (catálogo, secciones,
// lanzamiento activo) — no requieren token de Admin.
//
// OJO CORS: el backend solo acepta requests desde un origen conocido
// (underlaw.site, o http://localhost:3000/5173 en desarrollo). Si corres esta
// app con `flutter run -d chrome`, usa el puerto 3000:
//   flutter run -d chrome --web-port 3000
// Cualquier otro puerto será rechazado por CORS al llamar a estos endpoints.
class ApiService {
  static const String baseUrl = 'https://underlaw-production.up.railway.app';

  static Future<dynamic> _get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Error ${res.statusCode} al pedir $path');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  static Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final decoded = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final mensaje = (decoded is Map && decoded['error'] != null) ? decoded['error'] : 'Error ${res.statusCode}';
      throw Exception(mensaje);
    }
    return decoded;
  }

  /// { lanzamiento: {...} | null, server_now: "2026-..." }
  static Future<Map<String, dynamic>> getLanzamientoHome() async {
    final data = await _get('/api/lanzamientos/home');
    return data as Map<String, dynamic>;
  }

  /// Catálogo público (solo productos activos).
  static Future<List<dynamic>> getCatalogo() async {
    final data = await _get('/api/catalogo');
    return data as List<dynamic>;
  }

  /// Secciones (pestañas de la Colección).
  static Future<List<dynamic>> getSecciones() async {
    final data = await _get('/api/secciones');
    return data as List<dynamic>;
  }

  // ── Checkout con Wompi (mismo flujo que src/pages/Products.jsx) ─────────

  /// Crea el pedido en PENDING y devuelve { reference, amountInCents,
  /// currency, publicKey, signature } para abrir el Widget de Wompi.
  static Future<Map<String, dynamic>> iniciarPago({
    required Map<String, dynamic> formData,
    required List<Map<String, dynamic>> cart,
  }) async {
    final data = await _post('/api/wompi/iniciar', {'formData': formData, 'cart': cart});
    return data as Map<String, dynamic>;
  }

  /// El Widget devolvió un resultado aprobado: confirma en el backend
  /// (la factura la genera y envía el servidor, no hace falta mandar PDF).
  static Future<void> confirmarPago(String reference) async {
    await _post('/api/wompi/confirmar', {'reference': reference});
  }

  /// El cliente cerró el Widget sin pagar, o el pago fue rechazado/anulado.
  static Future<void> cancelarPago(String reference, String estadoPago) async {
    await _post('/api/wompi/cancelar', {'reference': reference, 'estado_pago': estadoPago});
  }

  /// Estado real del pedido (para métodos que sacan al cliente de la app, tipo Nequi/PSE).
  static Future<Map<String, dynamic>> consultarEstado(String reference, {String? transactionId}) async {
    final query = transactionId != null ? '?transactionId=$transactionId' : '';
    final data = await _get('/api/wompi/estado/$reference$query');
    return data as Map<String, dynamic>;
  }
}
