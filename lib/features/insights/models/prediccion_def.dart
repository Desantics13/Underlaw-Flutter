/// Definición de una oración de predicción, tal como la entrega
/// GET /predicciones. La app arma la pregunta y sus controles solo con esto.
class PrediccionDef {
  final String id;
  final String titulo;
  final String tipoProblema;
  final String plantilla;
  final List<CampoDef> campos;

  PrediccionDef({
    required this.id,
    required this.titulo,
    required this.tipoProblema,
    required this.plantilla,
    required this.campos,
  });

  factory PrediccionDef.fromJson(Map<String, dynamic> json) => PrediccionDef(
    id: json['id'] as String,
    titulo: json['titulo'] as String,
    tipoProblema: json['tipo_problema'] as String,
    plantilla: json['plantilla'] as String,
    campos: (json['campos'] as List<dynamic>)
        .map((c) => CampoDef.fromJson(c as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> valoresPorDefecto() => {
    for (final c in campos) c.id: c.defecto,
  };

  CampoDef campo(String id) => campos.firstWhere((c) => c.id == id);
}

class OpcionDef {
  final String valor;
  final String etiqueta;

  const OpcionDef(this.valor, this.etiqueta);
}

/// Un campo editable de la oración: opción, número entero o dinero.
class CampoDef {
  final String id;
  final String tipo; // 'opcion' | 'entero' | 'dinero'
  final String etiqueta;
  final dynamic defecto;
  final num? min;
  final num? max;
  final num? paso;
  final List<OpcionDef> opciones;
  final String? formatoSingular;
  final String? formatoPlural;

  CampoDef({
    required this.id,
    required this.tipo,
    required this.etiqueta,
    required this.defecto,
    this.min,
    this.max,
    this.paso,
    this.opciones = const [],
    this.formatoSingular,
    this.formatoPlural,
  });

  factory CampoDef.fromJson(Map<String, dynamic> json) {
    final formato = json['formato'] as Map<String, dynamic>?;
    return CampoDef(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      etiqueta: json['etiqueta'] as String,
      defecto: json['defecto'],
      min: json['min'] as num?,
      max: json['max'] as num?,
      paso: json['paso'] as num?,
      opciones: (json['opciones'] as List<dynamic>? ?? [])
          .map(
            (o) => OpcionDef(o['valor'].toString(), o['etiqueta'].toString()),
          )
          .toList(),
      formatoSingular: formato?['singular'] as String?,
      formatoPlural: formato?['plural'] as String?,
    );
  }

  bool get esOpcion => tipo == 'opcion';
  bool get esDinero => tipo == 'dinero';

  /// Texto que aparece dentro de la oración para un valor dado.
  String texto(dynamic valor) {
    if (esOpcion) {
      return opciones
          .firstWhere(
            (o) => o.valor == valor,
            orElse: () => OpcionDef('$valor', '$valor'),
          )
          .etiqueta;
    }
    final n = (valor as num).toInt();
    if (esDinero) return '\$${_miles(n)}';
    if (formatoSingular != null && formatoPlural != null) {
      return (n == 1 ? formatoSingular! : formatoPlural!).replaceAll(
        '{n}',
        '$n',
      );
    }
    return '$n';
  }

  static String _miles(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return n < 0 ? '-$buf' : buf.toString();
  }
}
