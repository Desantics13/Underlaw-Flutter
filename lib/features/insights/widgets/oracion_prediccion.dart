import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/core/widgets/ul_button.dart';
import 'package:underlaw_flutter/features/insights/models/prediccion_def.dart';

/// La pregunta de predicción como una oración: los valores editables se ven en
/// dorado y al tocarlos se abre su editor.
class OracionPrediccion extends StatelessWidget {
  final PrediccionDef def;
  final Map<String, dynamic> valores;
  final bool habilitada;
  final void Function(String idCampo, dynamic valor) onCambio;

  const OracionPrediccion({
    super.key,
    required this.def,
    required this.valores,
    required this.onCambio,
    this.habilitada = true,
  });

  static final _token = RegExp(r'\{(\w+)\}');

  @override
  Widget build(BuildContext context) {
    final estilo = GoogleFonts.jost(
      fontSize: 16,
      height: 1.9,
      color: AppColors.textSecondary,
    );
    final partes = <InlineSpan>[];
    var desde = 0;
    for (final m in _token.allMatches(def.plantilla)) {
      partes.add(TextSpan(text: def.plantilla.substring(desde, m.start)));
      final campo = def.campo(m.group(1)!);
      partes.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _Token(
            texto: campo.texto(valores[campo.id]),
            onTap: habilitada ? () => _editar(context, campo) : null,
          ),
        ),
      );
      desde = m.end;
    }
    partes.add(TextSpan(text: def.plantilla.substring(desde)));
    return Text.rich(TextSpan(style: estilo, children: partes));
  }

  Future<void> _editar(BuildContext context, CampoDef campo) async {
    HapticFeedback.selectionClick();
    final nuevo = await showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (_) => _EditorCampo(campo: campo, valor: valores[campo.id]),
    );
    if (nuevo != null) onCambio(campo.id, nuevo);
  }
}

class _Token extends StatelessWidget {
  final String texto;
  final VoidCallback? onTap;

  const _Token({required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.goldA10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.goldA45),
        ),
        child: Text(
          texto,
          style: GoogleFonts.jost(
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w500,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }
}

/// Editor de un campo: lista para opciones; deslizador y botones ± para números.
class _EditorCampo extends StatefulWidget {
  final CampoDef campo;
  final dynamic valor;

  const _EditorCampo({required this.campo, required this.valor});

  @override
  State<_EditorCampo> createState() => _EditorCampoState();
}

class _EditorCampoState extends State<_EditorCampo> {
  late dynamic _valor = widget.valor;

  CampoDef get c => widget.campo;

  void _sumar(int signo) {
    final paso = (c.paso ?? 1).toInt();
    final n = ((_valor as num).toInt() + signo * paso).clamp(
      c.min!.toInt(),
      c.max!.toInt(),
    );
    HapticFeedback.selectionClick();
    setState(() => _valor = n);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 32,
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Text(c.etiqueta.toUpperCase(), style: kickerStyle()),
            const SizedBox(height: 16),
            if (c.esOpcion) ..._opciones() else ..._numero(),
          ],
        ),
      ),
    );
  }

  List<Widget> _opciones() => [
    for (final o in c.opciones)
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).pop(o.valor);
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  o.etiqueta,
                  style: GoogleFonts.jost(
                    fontSize: 15,
                    color: o.valor == _valor
                        ? AppColors.gold
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (o.valor == _valor)
                const Icon(Symbols.check, size: 20, color: AppColors.gold),
            ],
          ),
        ),
      ),
  ];

  List<Widget> _numero() {
    final min = c.min!.toDouble(), max = c.max!.toDouble();
    final paso = (c.paso ?? 1).toDouble();
    final divisiones = ((max - min) / paso).round();
    return [
      Row(
        children: [
          _BotonRedondo(icon: Symbols.remove, onTap: () => _sumar(-1)),
          Expanded(
            child: Text(
              c.texto(_valor),
              textAlign: TextAlign.center,
              style: serifTitle(size: 30)
                  .copyWith(color: AppColors.gold, height: 1.1),
            ),
          ),
          _BotonRedondo(icon: Symbols.add, onTap: () => _sumar(1)),
        ],
      ),
      const SizedBox(height: 12),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: AppColors.gold,
          inactiveTrackColor: AppColors.border,
          thumbColor: AppColors.gold,
          overlayColor: AppColors.goldA12,
          trackHeight: 3,
          showValueIndicator: ShowValueIndicator.never,
        ),
        child: Slider(
          min: min,
          max: max,
          divisions: divisiones > 0 ? divisiones : null,
          value: (_valor as num).toDouble().clamp(min, max),
          onChanged: (v) => setState(() => _valor = v.round()),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              c.texto(c.min!),
              style: GoogleFonts.jost(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
            Text(
              c.texto(c.max!),
              style: GoogleFonts.jost(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      UlButton(
        label: 'Listo',
        onPressed: () => Navigator.of(context).pop(_valor),
      ),
    ];
  }
}

class _BotonRedondo extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BotonRedondo({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 22, weight: 300, color: AppColors.textPrimary),
      ),
    );
  }
}
