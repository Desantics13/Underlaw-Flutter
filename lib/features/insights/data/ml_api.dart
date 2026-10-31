import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Error del servicio de predicción, con el mensaje que devuelve la API.
class MlApiException implements Exception {
  final String mensaje;
  final int? codigo;

  const MlApiException(this.mensaje, [this.codigo]);

  @override
  String toString() => mensaje;
}

/// Cliente del servicio de predicción (mineria/service, FastAPI).
///
/// Es un servicio APARTE del backend de la tienda: el catálogo y los pagos
/// siguen yendo a ApiService. La dirección se define al compilar:
///   flutter run --dart-define=ML_API_URL=http://192.168.1.20:8000
/// Sin ese parámetro: en desarrollo usa localhost (web) o 10.0.2.2 (emulador
/// Android); en release queda deshabilitado y la app lo indica en pantalla.
class MlApi {
  static const _definida = String.fromEnvironment('ML_API_URL');
  static const _timeout = Duration(seconds: 20);

  static String get baseUrl {
    if (_definida.isNotEmpty) return _definida;
    if (kReleaseMode) return '';
    return kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';
  }

  static bool get configurado => baseUrl.isNotEmpty;

  static Future<dynamic> _get(String ruta) async {
    _asegurarConfigurado();
    try {
      final res = await http.get(Uri.parse('$baseUrl$ruta')).timeout(_timeout);
      return _decodificar(res);
    } on MlApiException {
      rethrow;
    } catch (_) {
      throw const MlApiException(
        'No se pudo conectar con el servicio de predicción.',
      );
    }
  }

  static Future<dynamic> _post(String ruta, Map<String, dynamic> cuerpo) async {
    _asegurarConfigurado();
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl$ruta'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(cuerpo),
          )
          .timeout(_timeout);
      return _decodificar(res);
    } on MlApiException {
      rethrow;
    } catch (_) {
      throw const MlApiException(
        'No se pudo conectar con el servicio de predicción.',
      );
    }
  }

  static void _asegurarConfigurado() {
    if (!configurado) {
      throw const MlApiException(
        'Esta versión de la app no tiene configurado el servicio de predicción.',
      );
    }
  }

  static dynamic _decodificar(http.Response res) {
    final datos = res.body.isEmpty
        ? null
        : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final mensaje = datos is Map && datos['error'] != null
          ? datos['error'].toString()
          : 'Error ${res.statusCode}';
      throw MlApiException(mensaje, res.statusCode);
    }
    return datos;
  }

  /// { estado, modelos_entrenados, fuente_entrenamiento, fecha_corte_datos, datos }
  static Future<Map<String, dynamic>> salud() async =>
      await _get('/health') as Map<String, dynamic>;

  /// Catálogo de oraciones de predicción.
  static Future<List<dynamic>> catalogo() async =>
      (await _get('/predicciones') as Map<String, dynamic>)['predicciones']
          as List<dynamic>;

  /// Ejecuta el modelo en el servicio con los valores de la oración.
  static Future<Map<String, dynamic>> predecir(
    String id,
    Map<String, dynamic> valores,
  ) async =>
      await _post('/predecir/$id', {'valores': valores})
          as Map<String, dynamic>;

  /// Datos de las gráficas de una predicción (incluye su referencia).
  static Future<Map<String, dynamic>> graficas(String idPrediccion) async =>
      await _get('/graficas/$idPrediccion') as Map<String, dynamic>;
}
