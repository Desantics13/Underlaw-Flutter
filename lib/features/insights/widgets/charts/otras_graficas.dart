import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphic/graphic.dart' as g;
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/features/insights/util/etiquetas.dart';
import 'package:underlaw_flutter/features/insights/widgets/charts/tema_graficas.dart';

double _num(dynamic v) => (v as num).toDouble();
String _pct(double v) => '${(v * 100).toStringAsFixed(0)} %';

// ─────────────────────────── Syncfusion Gauges ───────────────────────────
/// Medidor radial de la probabilidad de recompra con el umbral de decisión.
class Medidor extends StatelessWidget {
  final DatosGrafica datos;
  const Medidor({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    final valor = _num(datos['valor']) * 100;
    final umbral = _num(datos['umbral']) * 100;
    final vuelve = datos['clase'] == 'recompra';
    return GraficaCard(
      titulo: datos['titulo'],
      descripcion: datos['descripcion'],
      libreria: 'Syncfusion Gauges',
      altura: 240,
      child: SfRadialGauge(
        enableLoadingAnimation: true,
        animationDuration: 1200,
        axes: [
          RadialAxis(
            minimum: 0,
            maximum: 100,
            startAngle: 150,
            endAngle: 30,
            interval: 25,
            showLastLabel: true,
            labelOffset: 18,
            axisLabelStyle: GaugeTextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
            majorTickStyle: const MajorTickStyle(
              length: 6,
              color: AppColors.textTertiary,
            ),
            minorTicksPerInterval: 4,
            minorTickStyle: const MinorTickStyle(
              length: 3,
              color: AppColors.border,
            ),
            axisLineStyle: const AxisLineStyle(
              thickness: 0.14,
              thicknessUnit: GaugeSizeUnit.factor,
              color: AppColors.border,
              cornerStyle: CornerStyle.bothCurve,
            ),
            pointers: [
              RangePointer(
                value: valor,
                width: 0.14,
                sizeUnit: GaugeSizeUnit.factor,
                cornerStyle: CornerStyle.bothCurve,
                enableAnimation: true,
                gradient: const SweepGradient(
                  colors: [Color(0x55C0A15B), AppColors.gold],
                  stops: [0.2, 1],
                ),
              ),
              MarkerPointer(
                value: umbral,
                markerType: MarkerType.invertedTriangle,
                markerHeight: 12,
                markerWidth: 12,
                markerOffset: -8,
                color: AppColors.textPrimary,
              ),
              NeedlePointer(
                value: valor,
                enableAnimation: true,
                needleLength: 0.62,
                needleStartWidth: 0.5,
                needleEndWidth: 3,
                needleColor: AppColors.gold,
                knobStyle: const KnobStyle(
                  knobRadius: 0.06,
                  color: AppColors.bgPrimary,
                  borderColor: AppColors.gold,
                  borderWidth: 0.03,
                ),
              ),
            ],
            annotations: [
              GaugeAnnotation(
                angle: 90,
                positionFactor: 0.55,
                widget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${valor.toStringAsFixed(0)} %',
                      style: serifTitle(size: 34)
                          .copyWith(color: AppColors.gold),
                    ),
                    Text(
                      vuelve ? 'VOLVERÍA A COMPRAR' : 'NO VOLVERÍA',
                      style: GoogleFonts.jost(
                        fontSize: 9,
                        letterSpacing: 2,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── fl_chart ───────────────────────────
/// Barras agrupadas: cada métrica comparando los modelos.
class BarrasMetricas extends StatefulWidget {
  final DatosGrafica datos;
  const BarrasMetricas({super.key, required this.datos});

  @override
  State<BarrasMetricas> createState() => _BarrasMetricasState();
}

class _BarrasMetricasState extends State<BarrasMetricas> {
  int _metrica = 0;

  @override
  Widget build(BuildContext context) {
    final d = widget.datos;
    final metricas = (d['metricas'] as List).cast<String>();
    final modelos = (d['modelos'] as List).cast<DatosGrafica>();
    final clave = metricas[_metrica];
    final valores = [
      for (final m in modelos) _num((m['valores'] as DatosGrafica)[clave]),
    ];
    final maximo = valores.reduce(math.max);
    final mejorEs = d['mejor_es'] is Map
        ? (d['mejor_es'] as DatosGrafica)[clave]
        : d['mejor_es'];
    return GraficaCard(
      titulo: d['titulo'],
      descripcion: d['descripcion'],
      libreria: 'fl_chart',
      altura: 230,
      child: Column(
        children: [
          // Selector de métrica (toca para cambiar).
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < metricas.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(etiquetaMetrica(metricas[i])),
                      selected: i == _metrica,
                      onSelected: (_) => setState(() => _metrica = i),
                      showCheckmark: false,
                      labelStyle: GoogleFonts.jost(
                        fontSize: 12,
                        color: i == _metrica
                            ? AppColors.gold
                            : AppColors.textSecondary,
                      ),
                      backgroundColor: Colors.transparent,
                      selectedColor: AppColors.goldA10,
                      side: BorderSide(
                        color: i == _metrica
                            ? AppColors.gold
                            : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mejorEs == 'mayor' ? 'Más alto es mejor' : 'Más bajo es mejor',
            style: GoogleFonts.jost(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maximo * 1.25,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      // El tope del eje no cae en la cuadrícula: se omite para
                      // que no se monte sobre la etiqueta anterior.
                      getTitlesWidget: (v, meta) => v == meta.max
                          ? const SizedBox.shrink()
                          : SideTitleWidget(
                              meta: meta,
                              child: Text(
                                // Errores en unidades (MAE, RMSE) sin decimales.
                                meta.max >= 10
                                    ? '${v.toStringAsFixed(0)}${clave == 'MAPE_%' ? ' %' : ''}'
                                    : valorMetrica(clave, v),
                                style: TemaGraficas.eje.copyWith(fontSize: 8),
                              ),
                            ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(
                          (modelos[v.toInt()]['modelo'] as String).replaceAll(
                            ' (',
                            '\n(',
                          ),
                          textAlign: TextAlign.center,
                          style: TemaGraficas.eje.copyWith(fontSize: 9),
                        ),
                      ),
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.bgPrimary,
                    tooltipBorder: const BorderSide(color: AppColors.border),
                    getTooltipItem: (grupo, _, rod, _) => BarTooltipItem(
                      '${modelos[grupo.x]['modelo']}\n',
                      TemaGraficas.tooltip,
                      children: [
                        TextSpan(
                          text:
                              '${etiquetaMetrica(clave)} ${valorMetrica(clave, rod.toY)}',
                          style: TemaGraficas.tooltip.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < modelos.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: valores[i],
                          width: 34,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          color: TemaGraficas.modelo(
                            i,
                            modelos[i]['ganador'] == true,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              duration: const Duration(milliseconds: 450),
              curve: AppMotion.curve,
            ),
          ),
        ],
      ),
    );
  }
}

/// Radar con el perfil relativo de cada segmento (el de la consulta resaltado).
class RadarSegmentos extends StatelessWidget {
  final DatosGrafica datos;
  const RadarSegmentos({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    final ejes = (datos['ejes'] as List).cast<String>();
    final segmentos = (datos['segmentos'] as List).cast<DatosGrafica>();
    final resaltado = datos['resaltado'] as String;
    return GraficaCard(
      titulo: datos['titulo'],
      descripcion: datos['descripcion'],
      libreria: 'fl_chart',
      altura: 290,
      child: Column(
        children: [
          Expanded(
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle: const TextStyle(
                  color: Colors.transparent,
                  fontSize: 1,
                ),
                tickBorderData: const BorderSide(color: AppColors.border),
                gridBorderData: const BorderSide(color: AppColors.border),
                radarBorderData: const BorderSide(color: AppColors.border),
                titleTextStyle: TemaGraficas.eje,
                titlePositionPercentageOffset: 0.12,
                getTitle: (i, _) => RadarChartTitle(text: ejes[i]),
                dataSets: [
                  for (final s in segmentos)
                    RadarDataSet(
                      dataEntries: [
                        for (final v in s['valores'] as List)
                          RadarEntry(value: _num(v)),
                      ],
                      fillColor: TemaGraficas.segmento(s['segmento'] as String)
                          .withValues(
                            alpha: s['segmento'] == resaltado ? 0.30 : 0.05,
                          ),
                      borderColor: TemaGraficas.segmento(
                        s['segmento'] as String,
                      ).withValues(alpha: s['segmento'] == resaltado ? 1 : 0.5),
                      borderWidth: s['segmento'] == resaltado ? 2.4 : 1.2,
                      entryRadius: s['segmento'] == resaltado ? 3 : 1.5,
                    ),
                ],
              ),
              duration: const Duration(milliseconds: 500),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final s in segmentos)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: TemaGraficas.segmento(s['segmento'] as String),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s['segmento'] as String,
                      style: TemaGraficas.leyenda.copyWith(
                        color: s['segmento'] == resaltado
                            ? AppColors.gold
                            : AppColors.textSecondary,
                        fontWeight: s['segmento'] == resaltado
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── graphic ───────────────────────────
/// Mapa de calor genérico (filas × columnas) con selección al tocar.
class _MapaCalorGraphic extends StatelessWidget {
  final List<String> filas;
  final List<String> columnas;
  final List<List<num>> valores;
  final bool etiquetas;

  const _MapaCalorGraphic({
    required this.filas,
    required this.columnas,
    required this.valores,
    this.etiquetas = false,
  });

  @override
  Widget build(BuildContext context) {
    final datos = <DatosGrafica>[
      for (var f = 0; f < filas.length; f++)
        for (var c = 0; c < columnas.length; c++)
          {'fila': filas[f], 'columna': columnas[c], 'valor': valores[f][c]},
    ];
    final ejeEstilo = g.LabelStyle(textStyle: TemaGraficas.eje);
    return g.Chart<DatosGrafica>(
      data: datos,
      variables: {
        'columna': g.Variable(
          accessor: (m) => m['columna'] as String,
          scale: g.OrdinalScale(values: columnas),
        ),
        'fila': g.Variable(
          accessor: (m) => m['fila'] as String,
          scale: g.OrdinalScale(values: filas),
        ),
        'valor': g.Variable(accessor: (m) => m['valor'] as num),
      },
      marks: [
        g.PolygonMark(
          color: g.ColorEncode(
            variable: 'valor',
            values: const [
              Color(0xFF0E0E0D),
              Color(0xFF5C4D2B),
              AppColors.gold,
            ],
            updaters: {
              'toque': {false: (c) => c.withValues(alpha: 0.35)},
            },
          ),
          label: etiquetas
              ? g.LabelEncode(
                  encoder: (t) => g.Label(
                    '${t['valor']}',
                    g.LabelStyle(
                      textStyle: GoogleFonts.jost(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ],
      axes: [
        g.AxisGuide(label: ejeEstilo),
        g.AxisGuide(label: ejeEstilo),
      ],
      selections: {
        'toque': g.PointSelection(on: {g.GestureType.tap}, dim: g.Dim.x),
      },
      tooltip: g.TooltipGuide(
        backgroundColor: AppColors.bgPrimary,
        textStyle: TemaGraficas.tooltip,
        radius: const Radius.circular(8),
        variables: const ['fila', 'columna', 'valor'],
      ),
    );
  }
}

class MapaCalor extends StatelessWidget {
  final DatosGrafica datos;
  const MapaCalor({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    final semanas = (datos['semanas'] as List).cast<String>();
    final valores = (datos['valores'] as List)
        .map((f) => (f as List).cast<num>())
        .toList();
    // Últimas 12 semanas para que las celdas se lean bien en el celular.
    final desde = math.max(0, semanas.length - 12);
    return GraficaCard(
      titulo: datos['titulo'],
      descripcion: '${datos['descripcion']} Toca una celda para ver su valor.',
      libreria: 'graphic',
      altura: 300,
      child: _MapaCalorGraphic(
        filas: [for (final s in semanas.sublist(desde)) fechaCorta(s)],
        columnas: (datos['dias'] as List).cast<String>(),
        valores: valores.sublist(desde),
      ),
    );
  }
}

class MatrizConfusion extends StatelessWidget {
  final DatosGrafica datos;
  const MatrizConfusion({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    final etiquetas = (datos['etiquetas'] as List).cast<String>();
    final valores = (datos['valores'] as List)
        .map((f) => (f as List).cast<num>())
        .toList();
    final total = valores.expand((f) => f).fold<num>(0, (a, b) => a + b);
    final aciertos = valores[0][0] + valores[1][1];
    return GraficaCard(
      titulo: datos['titulo'],
      descripcion:
          '${datos['descripcion']} Filas: lo real · columnas: lo predicho.',
      libreria: 'graphic',
      altura: 230,
      accion: Text(
        'Aciertos: $aciertos de $total (${_pct(aciertos / total)})',
        style: GoogleFonts.jost(fontSize: 12, color: AppColors.textSecondary),
      ),
      child: _MapaCalorGraphic(
        filas: [for (final e in etiquetas) 'Real: $e'],
        columnas: [for (final e in etiquetas) 'Pred.: $e'],
        valores: valores,
        etiquetas: true,
      ),
    );
  }
}

// ─────────────────────────── barras propias ───────────────────────────
class _BarraHorizontal extends StatelessWidget {
  final String etiqueta;
  final double valor; // 0–1
  final String texto;
  final Color color;
  final bool destacada;

  const _BarraHorizontal({
    required this.etiqueta,
    required this.valor,
    required this.texto,
    required this.color,
    this.destacada = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  etiqueta,
                  style: GoogleFonts.jost(
                    fontSize: 13,
                    color: destacada ? AppColors.gold : AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                texto,
                style: precioStyle(
                  size: 13,
                  color: destacada ? AppColors.gold : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: valor.clamp(0, 1)),
              duration: const Duration(milliseconds: 800),
              curve: AppMotion.curve,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BarrasProbabilidad extends StatelessWidget {
  final DatosGrafica datos;
  const BarrasProbabilidad({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    final modelos = (datos['modelos'] as List).cast<DatosGrafica>();
    return GraficaCard(
      titulo: datos['titulo'],
      descripcion: datos['descripcion'],
      libreria: 'Flutter (propia)',
      altura: null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < modelos.length; i++)
            _BarraHorizontal(
              etiqueta:
                  modelos[i]['modelo'] +
                  (modelos[i]['ganador'] == true ? ' ★' : ''),
              valor: _num(modelos[i]['probabilidad']),
              texto: _pct(_num(modelos[i]['probabilidad'])),
              color: TemaGraficas.modelo(i, modelos[i]['ganador'] == true),
              destacada: modelos[i]['ganador'] == true,
            ),
        ],
      ),
    );
  }
}

class ImportanciaVariables extends StatelessWidget {
  final DatosGrafica datos;
  const ImportanciaVariables({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    final variables = (datos['variables'] as List).cast<DatosGrafica>();
    final maximo = variables
        .map((v) => _num(v['importancia']))
        .reduce(math.max);
    return GraficaCard(
      titulo: datos['titulo'],
      descripcion: datos['descripcion'],
      libreria: 'Flutter (propia)',
      altura: null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < variables.length; i++)
            _BarraHorizontal(
              etiqueta: variables[i]['etiqueta'] as String,
              valor: maximo > 0
                  ? _num(variables[i]['importancia']) / maximo
                  : 0,
              texto: _num(variables[i]['importancia'])
                  .toStringAsFixed(3)
                  .replaceAll('.', ','),
              color: i == 0
                  ? AppColors.gold
                  : AppColors.gold.withValues(alpha: 0.45),
              destacada: i == 0,
            ),
        ],
      ),
    );
  }
}
