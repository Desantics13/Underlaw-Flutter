import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/features/insights/widgets/graficas_section.dart';
import 'package:underlaw_flutter/features/insights/widgets/mineria_section.dart';

// Pestaña Insights: dos secciones. "Minería y predicciones" (resultados de los
// modelos en Python) y "Gráficas" (Flutter). Hoy ambas usan datos de ejemplo.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int _seccion = 0; // 0 minería · 1 gráficas
  final _scroll = ScrollController();

  void _elegir(int i) {
    if (i == _seccion) return;
    HapticFeedback.selectionClick();
    setState(() => _seccion = i);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = math.max(MediaQuery.paddingOf(context).top, 20.0);
    return ListView(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(20, top + 24, 20, 140),
      children: [
        Text('MINERÍA DE DATOS', style: kickerStyle()),
        const SizedBox(height: 14),
        Text('INSIGHTS', style: serifTitle(size: 44).copyWith(height: 1)),
        const SizedBox(height: 24),
        _Selector(seleccion: _seccion, onSelect: _elegir),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: AppMotion.base,
          switchInCurve: AppMotion.curve,
          switchOutCurve: AppMotion.curve,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(_seccion),
            child: _seccion == 0
                ? MineriaSection(onVerGraficas: () => _elegir(1))
                : const GraficasSection(),
          ),
        ),
      ],
    );
  }
}

// Selector de dos secciones con indicador dorado deslizante (340 ms).
class _Selector extends StatelessWidget {
  final int seleccion;
  final ValueChanged<int> onSelect;

  static const _items = ['Minería y predicciones', 'Gráficas'];

  const _Selector({required this.seleccion, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 340),
            curve: AppMotion.curve,
            alignment: seleccion == 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.goldA12,
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(color: AppColors.goldA45),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(i),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: AppMotion.fast,
                        curve: AppMotion.curve,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jost(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                          color: seleccion == i
                              ? AppColors.gold
                              : AppColors.textTertiary,
                        ),
                        child: Text(_items[i].toUpperCase()),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
