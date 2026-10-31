import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/features/insights/widgets/charts/tema_graficas.dart';

// Gráficas hechas con Syncfusion: zoom con pellizco, desplazamiento, trackball
// y leyenda que activa/desactiva series.

DateTime _fecha(dynamic iso) => DateTime.parse(iso as String);
double _num(dynamic v) => (v as num).toDouble();

/// Etiquetas de eje con coma decimal (formato colombiano).
ChartAxisLabel _coma(AxisLabelRenderDetails a) =>
    ChartAxisLabel(a.text.replaceAll('.', ','), a.textStyle);

/// Etiquetas de un eje 0–1 como porcentaje.
ChartAxisLabel _porcentaje(AxisLabelRenderDetails a) =>
    ChartAxisLabel('${(a.value * 100).round()} %', a.textStyle);

Legend _leyenda() => Legend(
  isVisible: true,
  position: LegendPosition.bottom,
  toggleSeriesVisibility: true,
  overflowMode: LegendItemOverflowMode.wrap,
  textStyle: TemaGraficas.leyenda,
  iconHeight: 10,
  iconWidth: 10,
);

TrackballBehavior _trackball() => TrackballBehavior(
  enable: true,
  activationMode: ActivationMode.singleTap,
  tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
  lineColor: AppColors.goldA45,
  lineDashArray: const [4, 4],
  tooltipSettings: InteractiveTooltip(
    color: AppColors.bgPrimary,
    borderColor: AppColors.border,
    borderWidth: 1,
    textStyle: TemaGraficas.tooltip,
  ),
  markerSettings: const TrackballMarkerSettings(
    markerVisibility: TrackballVisibilityMode.visible,
  ),
);

ZoomPanBehavior _zoom({ZoomMode modo = ZoomMode.x}) => ZoomPanBehavior(
  enablePinching: true,
  enablePanning: true,
  enableDoubleTapZooming: true,
  enableMouseWheelZooming: true,
  zoomMode: modo,
);

NumericAxis _ejeY({
  String? nombre,
  bool opuesto = false,
  double? min,
  double? max,
  String? formato,
}) => NumericAxis(
  name: nombre,
  opposedPosition: opuesto,
  minimum: min,
  maximum: max,
  labelFormat: formato,
  axisLabelFormatter: _coma,
  labelStyle: TemaGraficas.eje,
  axisLine: const AxisLine(width: 0),
  majorTickLines: const MajorTickLines(size: 0),
  majorGridLines: const MajorGridLines(color: AppColors.border, width: 1),
);

/// Zoom bajo demanda. Con el zoom activo la gráfica captura los arrastres
/// (pellizco y desplazamiento); por eso empieza apagado: así, al deslizar el
/// dedo sobre la gráfica, la página sigue haciendo scroll con normalidad.
mixin _ZoomBajoDemanda<T extends StatefulWidget> on State<T> {
  ZoomMode get modoZoom => ZoomMode.x;
  bool _zoomActivo = false;
  int _version = 0;
  late ZoomPanBehavior _zoomPan = _zoom(modo: modoZoom);

  ZoomPanBehavior? get zoomPan => _zoomActivo ? _zoomPan : null;

  /// Clave de la gráfica: cambia en cada alternancia para que Syncfusion la
  /// reconstruya limpia (sin restos del zoom anterior en el diseño de ejes).
  Key get claveGrafica => ValueKey(_version);

  void _alternarZoom() => setState(() {
    _zoomActivo = !_zoomActivo;
    _version++;
    _zoomPan = _zoom(modo: modoZoom);
  });

  Widget get controlesZoom => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      if (_zoomActivo)
        TextButton.icon(
          onPressed: _zoomPan.reset,
          icon: const Icon(Icons.zoom_out_map, size: 16, color: AppColors.gold),
          label: Text(
            'Restablecer',
            style: TemaGraficas.leyenda.copyWith(color: AppColors.gold),
          ),
        ),
      TextButton.icon(
        onPressed: _alternarZoom,
        icon: Icon(
          _zoomActivo ? Icons.zoom_in_map : Icons.zoom_in,
          size: 16,
          color: AppColors.gold,
        ),
        label: Text(
          _zoomActivo ? 'Terminar zoom' : 'Activar zoom',
          style: TemaGraficas.leyenda.copyWith(color: AppColors.gold),
        ),
      ),
    ],
  );
}

/// Histórico + proyección de cada modelo con bandas de confianza (80 % y 95 %).
class SerieProyeccion extends StatefulWidget {
  final DatosGrafica datos;
  const SerieProyeccion({super.key, required this.datos});

  @override
  State<SerieProyeccion> createState() => _SerieProyeccionState();
}

class _SerieProyeccionState extends State<SerieProyeccion>
    with _ZoomBajoDemanda {
  final _track = _trackball();

  @override
  Widget build(BuildContext context) {
    final d = widget.datos;
    final historial = (d['historial'] as List).cast<DatosGrafica>();
    final banda = (d['banda'] as List).cast<DatosGrafica>();
    final pronosticos = (d['pronosticos'] as List).cast<DatosGrafica>();
    final inicio = _fecha(d['inicio_pronostico']);
    // Último punto real unido a cada pronóstico para que la línea no quede cortada.
    final ultimo = historial.last;
    return GraficaCard(
      titulo: d['titulo'],
      descripcion: d['descripcion'],
      libreria: 'Syncfusion',
      altura: 300,
      accion: controlesZoom,
      child: SfCartesianChart(
        key: claveGrafica,
        plotAreaBorderWidth: 0,
        zoomPanBehavior: zoomPan,
        trackballBehavior: _track,
        legend: _leyenda(),
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat('dd/MM'),
          labelStyle: TemaGraficas.eje,
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(color: AppColors.border),
          initialVisibleMinimum: inicio.subtract(const Duration(days: 7 * 20)),
          plotBands: [
            PlotBand(
              start: inicio,
              end: _fecha(banda.last['fecha']),
              color: AppColors.gold.withValues(alpha: 0.04),
              text: 'PRONÓSTICO',
              textStyle: TemaGraficas.eje.copyWith(
                color: AppColors.gold,
                letterSpacing: 1.5,
              ),
              verticalTextAlignment: TextAnchor.start,
              horizontalTextAlignment: TextAnchor.start,
            ),
            for (final drop in (d['drops'] as List))
              PlotBand(
                start: _fecha(drop),
                end: _fecha(drop),
                borderWidth: 1,
                borderColor: AppColors.goldA45,
                dashArray: const [3, 3],
                text: 'DROP',
                textStyle: TemaGraficas.eje.copyWith(
                  fontSize: 8,
                  color: AppColors.goldA45,
                ),
                verticalTextAlignment: TextAnchor.end,
              ),
          ],
        ),
        primaryYAxis: _ejeY(),
        series: <CartesianSeries>[
          RangeAreaSeries<DatosGrafica, DateTime>(
            name: 'Banda 95 %',
            dataSource: banda,
            xValueMapper: (b, _) => _fecha(b['fecha']),
            lowValueMapper: (b, _) => _num(b['inferior95']),
            highValueMapper: (b, _) => _num(b['superior95']),
            color: AppColors.gold.withValues(alpha: 0.08),
            borderWidth: 0,
            enableTooltip: false,
          ),
          RangeAreaSeries<DatosGrafica, DateTime>(
            name: 'Banda 80 %',
            dataSource: banda,
            xValueMapper: (b, _) => _fecha(b['fecha']),
            lowValueMapper: (b, _) => _num(b['inferior80']),
            highValueMapper: (b, _) => _num(b['superior80']),
            color: AppColors.gold.withValues(alpha: 0.16),
            borderWidth: 0,
            enableTooltip: false,
          ),
          SplineSeries<DatosGrafica, DateTime>(
            name: 'Histórico',
            dataSource: historial,
            xValueMapper: (p, _) => _fecha(p['fecha']),
            yValueMapper: (p, _) => _num(p['valor']),
            color: AppColors.textPrimary,
            width: 2,
          ),
          for (var i = 0; i < pronosticos.length; i++)
            LineSeries<DatosGrafica, DateTime>(
              name:
                  pronosticos[i]['modelo'] +
                  (pronosticos[i]['ganador'] == true ? ' ★' : ''),
              dataSource: [
                {'fecha': ultimo['fecha'], 'valor': ultimo['valor']},
                ...(pronosticos[i]['puntos'] as List).cast<DatosGrafica>(),
              ],
              xValueMapper: (p, _) => _fecha(p['fecha']),
              yValueMapper: (p, _) => _num(p['valor']),
              color: TemaGraficas.modelo(i, pronosticos[i]['ganador'] == true),
              width: pronosticos[i]['ganador'] == true ? 2.6 : 1.5,
              dashArray: pronosticos[i]['ganador'] == true
                  ? null
                  : const <double>[6, 4],
              markerSettings: MarkerSettings(
                isVisible: pronosticos[i]['ganador'] == true,
                height: 5,
                width: 5,
                color: AppColors.bgSecondary,
                borderColor: AppColors.gold,
              ),
            ),
        ],
      ),
    );
  }
}

/// Validación: valores reales vs. lo que predijo cada modelo en las semanas de prueba.
class RealVsPredicho extends StatefulWidget {
  final DatosGrafica datos;
  const RealVsPredicho({super.key, required this.datos});

  @override
  State<RealVsPredicho> createState() => _RealVsPredichoState();
}

class _RealVsPredichoState extends State<RealVsPredicho>
    with _ZoomBajoDemanda {
  final _track = _trackball();

  @override
  Widget build(BuildContext context) {
    final d = widget.datos;
    final fechas = (d['fechas'] as List).map(_fecha).toList();
    final real = (d['real'] as List).map(_num).toList();
    final modelos = (d['modelos'] as List).cast<DatosGrafica>();
    List<DatosGrafica> puntos(List valores) => [
      for (var i = 0; i < fechas.length; i++)
        {'x': fechas[i], 'y': _num(valores[i])},
    ];
    return GraficaCard(
      titulo: d['titulo'],
      descripcion: d['descripcion'],
      libreria: 'Syncfusion',
      accion: controlesZoom,
      child: SfCartesianChart(
        key: claveGrafica,
        plotAreaBorderWidth: 0,
        zoomPanBehavior: zoomPan,
        trackballBehavior: _track,
        legend: _leyenda(),
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat('dd/MM'),
          labelStyle: TemaGraficas.eje,
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(color: AppColors.border),
        ),
        primaryYAxis: _ejeY(),
        series: <CartesianSeries>[
          ColumnSeries<DatosGrafica, DateTime>(
            name: 'Real',
            dataSource: puntos(real),
            xValueMapper: (p, _) => p['x'] as DateTime,
            yValueMapper: (p, _) => p['y'] as double,
            color: AppColors.textPrimary.withValues(alpha: 0.18),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            width: 0.7,
          ),
          for (var i = 0; i < modelos.length; i++)
            LineSeries<DatosGrafica, DateTime>(
              name:
                  modelos[i]['modelo'] +
                  (modelos[i]['ganador'] == true ? ' ★' : ''),
              dataSource: puntos(modelos[i]['valores'] as List),
              xValueMapper: (p, _) => p['x'] as DateTime,
              yValueMapper: (p, _) => p['y'] as double,
              color: TemaGraficas.modelo(i, modelos[i]['ganador'] == true),
              width: modelos[i]['ganador'] == true ? 2.4 : 1.4,
              markerSettings: const MarkerSettings(
                isVisible: true,
                height: 4,
                width: 4,
              ),
            ),
        ],
      ),
    );
  }
}

/// Curva ROC de cada modelo frente a la línea del azar.
class CurvaRoc extends StatefulWidget {
  final DatosGrafica datos;
  const CurvaRoc({super.key, required this.datos});

  @override
  State<CurvaRoc> createState() => _CurvaRocState();
}

class _CurvaRocState extends State<CurvaRoc> with _ZoomBajoDemanda {
  @override
  ZoomMode get modoZoom => ZoomMode.xy;
  final _track = _trackball();

  @override
  Widget build(BuildContext context) {
    final d = widget.datos;
    final modelos = (d['modelos'] as List).cast<DatosGrafica>();
    return GraficaCard(
      titulo: d['titulo'],
      descripcion: d['descripcion'],
      libreria: 'Syncfusion',
      altura: 280,
      accion: controlesZoom,
      child: SfCartesianChart(
        key: claveGrafica,
        plotAreaBorderWidth: 0,
        zoomPanBehavior: zoomPan,
        trackballBehavior: _track,
        legend: _leyenda(),
        primaryXAxis: NumericAxis(
          minimum: 0,
          maximum: 1,
          interval: 0.25,
          axisLabelFormatter: _coma,
          title: AxisTitle(
            text: 'Falsos positivos',
            textStyle: TemaGraficas.eje,
          ),
          labelStyle: TemaGraficas.eje,
          majorGridLines: const MajorGridLines(color: AppColors.border),
        ),
        primaryYAxis: _ejeY(min: 0, max: 1),
        series: <CartesianSeries>[
          LineSeries<List<double>, double>(
            name: 'Azar',
            dataSource: const [
              [0, 0],
              [1, 1],
            ],
            xValueMapper: (p, _) => p[0],
            yValueMapper: (p, _) => p[1],
            color: AppColors.textTertiary,
            width: 1,
            dashArray: const <double>[4, 4],
          ),
          for (var i = 0; i < modelos.length; i++)
            LineSeries<int, double>(
              name:
                  '${modelos[i]['modelo']} · AUC ${_num(modelos[i]['auc']).toStringAsFixed(3).replaceAll('.', ',')}',
              dataSource: List.generate(
                (modelos[i]['fpr'] as List).length,
                (j) => j,
              ),
              xValueMapper: (j, _) => _num(modelos[i]['fpr'][j]),
              yValueMapper: (j, _) => _num(modelos[i]['tpr'][j]),
              color: TemaGraficas.modelo(i, modelos[i]['ganador'] == true),
              width: modelos[i]['ganador'] == true ? 2.6 : 1.4,
            ),
        ],
      ),
    );
  }
}

/// "¿Y si…?": cómo cambia la probabilidad con los días sin comprar.
class CurvaSensibilidad extends StatefulWidget {
  final DatosGrafica datos;
  const CurvaSensibilidad({super.key, required this.datos});

  @override
  State<CurvaSensibilidad> createState() => _CurvaSensibilidadState();
}

class _CurvaSensibilidadState extends State<CurvaSensibilidad> {
  final _track = _trackball();

  @override
  Widget build(BuildContext context) {
    final d = widget.datos;
    final puntos = (d['puntos'] as List).cast<DatosGrafica>();
    final actual = d['actual'] as DatosGrafica;
    return GraficaCard(
      titulo: d['titulo'],
      descripcion: d['descripcion'],
      libreria: 'Syncfusion',
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        trackballBehavior: _track,
        primaryXAxis: NumericAxis(
          title: AxisTitle(text: d['eje_x'], textStyle: TemaGraficas.eje),
          labelStyle: TemaGraficas.eje,
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(color: AppColors.border),
        ),
        primaryYAxis: NumericAxis(
          minimum: 0,
          maximum: 1,
          interval: 0.25,
          axisLabelFormatter: _porcentaje,
          labelStyle: TemaGraficas.eje,
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(color: AppColors.border),
          plotBands: [
            PlotBand(
              start: 0.5,
              end: 0.5,
              borderWidth: 1,
              borderColor: AppColors.textTertiary,
              dashArray: const [4, 4],
            ),
            // Rótulo en una franja invisible justo encima de la línea, para
            // que la línea punteada no lo tache.
            PlotBand(
              start: 0.5,
              end: 0.6,
              color: Colors.transparent,
              text: 'UMBRAL 50 %',
              textStyle: TemaGraficas.eje.copyWith(fontSize: 8),
              horizontalTextAlignment: TextAnchor.end,
            ),
          ],
        ),
        series: <CartesianSeries>[
          SplineAreaSeries<DatosGrafica, double>(
            name: 'Probabilidad',
            dataSource: puntos,
            xValueMapper: (p, _) => _num(p['x']),
            yValueMapper: (p, _) => _num(p['y']),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.gold.withValues(alpha: 0.45),
                AppColors.gold.withValues(alpha: 0.02),
              ],
            ),
            borderColor: AppColors.gold,
            borderWidth: 2,
          ),
          ScatterSeries<DatosGrafica, double>(
            name: 'Esta consulta',
            dataSource: [actual],
            xValueMapper: (p, _) => _num(p['x']),
            yValueMapper: (p, _) => _num(p['y']),
            color: AppColors.gold,
            markerSettings: const MarkerSettings(
              height: 14,
              width: 14,
              shape: DataMarkerType.diamond,
              borderColor: AppColors.textPrimary,
              borderWidth: 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mapa de clientes (PCA) por segmento, centroides y la consulta actual.
class DispersionClusters extends StatefulWidget {
  final DatosGrafica datos;
  const DispersionClusters({super.key, required this.datos});

  @override
  State<DispersionClusters> createState() => _DispersionClustersState();
}

class _DispersionClustersState extends State<DispersionClusters>
    with _ZoomBajoDemanda {
  @override
  ZoomMode get modoZoom => ZoomMode.xy;
  late final _tooltip = TooltipBehavior(
    enable: true,
    color: AppColors.bgPrimary,
    borderColor: AppColors.border,
    borderWidth: 1,
    textStyle: TemaGraficas.tooltip,
    header: '',
    format: 'series.name',
  );

  @override
  Widget build(BuildContext context) {
    final d = widget.datos;
    final puntos = (d['puntos'] as List).cast<DatosGrafica>();
    final centroides = (d['centroides'] as List).cast<DatosGrafica>();
    final consulta = d['consulta'] as DatosGrafica;
    final varianza = (d['varianza_explicada'] as List).map(_num).toList();
    final segmentos = <String, List<DatosGrafica>>{};
    for (final p in puntos) {
      segmentos.putIfAbsent(p['segmento'] as String, () => []).add(p);
    }
    String pct(double v) => '${(v * 100).toStringAsFixed(0)} %';
    return GraficaCard(
      titulo: d['titulo'],
      descripcion: d['descripcion'],
      libreria: 'Syncfusion',
      altura: 320,
      accion: controlesZoom,
      child: SfCartesianChart(
        key: claveGrafica,
        plotAreaBorderWidth: 0,
        zoomPanBehavior: zoomPan,
        tooltipBehavior: _tooltip,
        legend: _leyenda(),
        primaryXAxis: NumericAxis(
          title: AxisTitle(
            text: 'Componente 1 (${pct(varianza[0])})',
            textStyle: TemaGraficas.eje,
          ),
          rangePadding: ChartRangePadding.round,
          decimalPlaces: 1,
          axisLabelFormatter: _coma,
          labelStyle: TemaGraficas.eje,
          majorGridLines: const MajorGridLines(color: AppColors.border),
          axisLine: const AxisLine(width: 0),
        ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(
            text: 'Componente 2 (${pct(varianza[1])})',
            textStyle: TemaGraficas.eje,
          ),
          rangePadding: ChartRangePadding.round,
          decimalPlaces: 1,
          axisLabelFormatter: _coma,
          labelStyle: TemaGraficas.eje,
          majorGridLines: const MajorGridLines(color: AppColors.border),
          axisLine: const AxisLine(width: 0),
        ),
        series: <CartesianSeries>[
          for (final e in segmentos.entries)
            ScatterSeries<DatosGrafica, double>(
              name: '${e.key} (${e.value.length})',
              dataSource: e.value,
              xValueMapper: (p, _) => _num(p['x']),
              yValueMapper: (p, _) => _num(p['y']),
              color: TemaGraficas.segmento(e.key).withValues(alpha: 0.55),
              markerSettings: const MarkerSettings(
                height: 6,
                width: 6,
                borderWidth: 0,
              ),
            ),
          ScatterSeries<DatosGrafica, double>(
            name: 'Centros',
            color: AppColors.textPrimary,
            dataSource: centroides,
            xValueMapper: (p, _) => _num(p['x']),
            yValueMapper: (p, _) => _num(p['y']),
            pointColorMapper: (p, _) =>
                TemaGraficas.segmento(p['segmento'] as String),
            markerSettings: const MarkerSettings(
              height: 14,
              width: 14,
              shape: DataMarkerType.rectangle,
              borderColor: AppColors.bgPrimary,
              borderWidth: 2,
            ),
          ),
          ScatterSeries<DatosGrafica, double>(
            name: 'Esta consulta',
            dataSource: [consulta],
            xValueMapper: (p, _) => _num(p['x']),
            yValueMapper: (p, _) => _num(p['y']),
            color: AppColors.gold,
            markerSettings: const MarkerSettings(
              height: 20,
              width: 20,
              shape: DataMarkerType.diamond,
              borderColor: AppColors.textPrimary,
              borderWidth: 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Codo (inercia) y silueta de K-means para elegir el número de grupos.
class CodoSilueta extends StatelessWidget {
  final DatosGrafica datos;
  const CodoSilueta({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    final d = datos;
    final puntos = (d['puntos'] as List).cast<DatosGrafica>();
    final k = _num(d['k_elegido']);
    return GraficaCard(
      titulo: d['titulo'],
      descripcion: d['descripcion'],
      libreria: 'Syncfusion',
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        trackballBehavior: _trackball(),
        legend: _leyenda(),
        primaryXAxis: NumericAxis(
          interval: 0.5,
          // Solo se rotulan los enteros (k = 2, 3, …).
          axisLabelFormatter: (a) => ChartAxisLabel(
            a.value % 1 == 0 ? '${a.value.toInt()}' : '',
            a.textStyle,
          ),
          majorTickLines: const MajorTickLines(size: 0),
          title: AxisTitle(
            text: 'Número de grupos (k)',
            textStyle: TemaGraficas.eje,
          ),
          labelStyle: TemaGraficas.eje,
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(color: AppColors.border),
          plotBands: [
            PlotBand(
              start: k - 0.4,
              end: k + 0.4,
              color: AppColors.gold.withValues(alpha: 0.10),
              text: 'k = ${k.toInt()}',
              textAngle: 0,
              textStyle: TemaGraficas.eje.copyWith(color: AppColors.gold),
              verticalTextAlignment: TextAnchor.start,
            ),
          ],
        ),
        primaryYAxis: _ejeY(),
        axes: [_ejeY(nombre: 'silueta', opuesto: true, min: 0, max: 0.5)],
        series: <CartesianSeries>[
          ColumnSeries<DatosGrafica, double>(
            name: 'Silueta',
            color: AppColors.gold,
            dataSource: puntos,
            yAxisName: 'silueta',
            xValueMapper: (p, _) => _num(p['k']),
            yValueMapper: (p, _) => _num(p['silueta']),
            pointColorMapper: (p, _) => _num(p['k']) == k
                ? AppColors.gold
                : AppColors.gold.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            width: 0.5,
          ),
          LineSeries<DatosGrafica, double>(
            name: 'Inercia (codo)',
            dataSource: puntos,
            xValueMapper: (p, _) => _num(p['k']),
            yValueMapper: (p, _) => _num(p['inercia']),
            color: AppColors.textPrimary,
            width: 2,
            markerSettings: const MarkerSettings(
              isVisible: true,
              height: 6,
              width: 6,
            ),
          ),
        ],
      ),
    );
  }
}
