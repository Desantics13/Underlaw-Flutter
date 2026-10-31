import 'package:flutter/foundation.dart';
import 'package:underlaw_flutter/features/insights/data/ml_api.dart';
import 'package:underlaw_flutter/features/insights/models/prediccion_def.dart';

enum EstadoCarga { cargando, listo, error }

/// Estado de la pestaña Insights: catálogo de oraciones, valores editados,
/// resultados de cada predicción y la predicción cuyas gráficas se ven.
class InsightsModel extends ChangeNotifier {
  EstadoCarga estado = EstadoCarga.cargando;
  String? error;
  Map<String, dynamic>? salud;
  List<PrediccionDef> catalogo = [];

  final Map<String, Map<String, dynamic>> valores = {};
  final Map<String, Map<String, dynamic>> resultados = {};
  final Map<String, bool> prediciendo = {};
  final Map<String, String> errores = {};

  /// Predicción seleccionada para la sección de gráficas.
  String? idPrediccionGraficas;
  Map<String, dynamic>? graficas;
  bool cargandoGraficas = false;
  String? errorGraficas;

  InsightsModel() {
    cargar();
  }

  Future<void> cargar() async {
    estado = EstadoCarga.cargando;
    error = null;
    notifyListeners();
    try {
      final respuestas = await Future.wait([MlApi.salud(), MlApi.catalogo()]);
      salud = respuestas[0] as Map<String, dynamic>;
      catalogo = (respuestas[1] as List<dynamic>)
          .map((p) => PrediccionDef.fromJson(p as Map<String, dynamic>))
          .toList();
      for (final p in catalogo) {
        valores.putIfAbsent(p.id, p.valoresPorDefecto);
      }
      estado = EstadoCarga.listo;
    } catch (e) {
      error = e.toString();
      estado = EstadoCarga.error;
    }
    notifyListeners();
  }

  void cambiarValor(String idPred, String idCampo, dynamic valor) {
    valores[idPred]![idCampo] = valor;
    errores.remove(idPred);
    notifyListeners();
  }

  Future<void> predecir(String idPred) async {
    prediciendo[idPred] = true;
    errores.remove(idPred);
    notifyListeners();
    try {
      resultados[idPred] = await MlApi.predecir(
        idPred,
        Map.of(valores[idPred]!),
      );
    } catch (e) {
      errores[idPred] = e.toString();
    }
    prediciendo[idPred] = false;
    notifyListeners();
  }

  /// Carga las gráficas de una predicción ya hecha (conserva su referencia).
  Future<void> verGraficas(String idPrediccion) async {
    idPrediccionGraficas = idPrediccion;
    graficas = null;
    errorGraficas = null;
    cargandoGraficas = true;
    notifyListeners();
    try {
      graficas = await MlApi.graficas(idPrediccion);
    } catch (e) {
      errorGraficas = e.toString();
    }
    cargandoGraficas = false;
    notifyListeners();
  }
}
