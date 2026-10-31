import 'package:flutter/material.dart';
import 'package:underlaw_flutter/features/insights/widgets/charts/otras_graficas.dart';
import 'package:underlaw_flutter/features/insights/widgets/charts/sf_graficas.dart';

/// Elige el widget de cada gráfica según su "tipo" (contrato de /graficas).
class GraficaWidget extends StatelessWidget {
  final Map<String, dynamic> datos;
  const GraficaWidget({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    return switch (datos['tipo']) {
      'serie_proyeccion' => SerieProyeccion(datos: datos),
      'real_vs_predicho' => RealVsPredicho(datos: datos),
      'barras_metricas' => BarrasMetricas(datos: datos),
      'mapa_calor' => MapaCalor(datos: datos),
      'medidor' => Medidor(datos: datos),
      'barras_probabilidad' => BarrasProbabilidad(datos: datos),
      'curva_sensibilidad' => CurvaSensibilidad(datos: datos),
      'curva_roc' => CurvaRoc(datos: datos),
      'matriz_confusion' => MatrizConfusion(datos: datos),
      'importancia_variables' => ImportanciaVariables(datos: datos),
      'dispersion_clusters' => DispersionClusters(datos: datos),
      'radar_segmentos' => RadarSegmentos(datos: datos),
      'codo_silueta' => CodoSilueta(datos: datos),
      _ => const SizedBox.shrink(),
    };
  }
}
