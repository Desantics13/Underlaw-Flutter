import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/core/widgets/striped_placeholder.dart';
import 'package:underlaw_flutter/core/widgets/ul_button.dart';

// Fotos del carrusel (assets/hero/). Para cambiarlas o agregar más, basta con
// reemplazar los archivos o añadir rutas a esta lista.
const _fotosHero = ['assets/hero/hero1.webp', 'assets/hero/hero2.webp'];

// Hero a pantalla completa con carrusel de fotos. El carrusel se mueve a 0.4×
// del scroll (parallax), cambia solo cada 5 s (o con el dedo) y el contenido
// se desvanece en los primeros 420 px.
class HomeHero extends StatefulWidget {
  final double height;
  final ValueListenable<double> offset;
  final VoidCallback onVerColeccion;
  final VoidCallback onProximoDrop;

  const HomeHero({
    super.key,
    required this.height,
    required this.offset,
    required this.onVerColeccion,
    required this.onProximoDrop,
  });

  @override
  State<HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends State<HomeHero> {
  final _page = PageController();
  Timer? _auto;
  int _actual = 0;

  @override
  void initState() {
    super.initState();
    _programarAvance();
  }

  // Avance automático; se reinicia cada vez que el usuario desliza.
  void _programarAvance() {
    _auto?.cancel();
    _auto = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_page.hasClients) return;
      final siguiente = (_actual + 1) % _fotosHero.length;
      _page.animateToPage(
        siguiente,
        duration: const Duration(milliseconds: 700),
        curve: AppMotion.curve,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: widget.height,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: widget.offset,
              builder: (_, s, child) => Positioned(
                top: -40 + s * 0.4,
                left: 0,
                right: 0,
                height: widget.height + 80,
                child: child!,
              ),
              child: NotificationListener<UserScrollNotification>(
                onNotification: (n) {
                  if (n.direction != ScrollDirection.idle) _programarAvance();
                  return false;
                },
                child: PageView.builder(
                  controller: _page,
                  itemCount: _fotosHero.length,
                  onPageChanged: (i) => setState(() => _actual = i),
                  itemBuilder: (_, i) => Image.asset(
                    _fotosHero[i],
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    // Si falta el archivo, vuelve a la zona rayada del diseño.
                    errorBuilder: (_, _, _) => const StripedPlaceholder(),
                  ),
                ),
              ),
            ),
            // Degradado superior: da lectura a la barra de estado y al indicador
            // aunque la foto sea clara.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [Color(0x99060606), Color(0x00060606)],
                    stops: [0.0, 0.25],
                  ),
                ),
              ),
            ),
            // Degradado inferior: el del diseño, adelantado para que el texto se lea
            // también sobre fotos claras (camiseta blanca).
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00060606),
                      Color(0xD9060606),
                      AppColors.bgPrimary,
                    ],
                    stops: [0.22, 0.50, 0.78],
                  ),
                ),
              ),
            ),
            // Indicador del carrusel (como los puntos de la web).
            Positioned(
              top: topInset + 20,
              left: 24,
              child: Row(
                children: [
                  for (var i = 0; i < _fotosHero.length; i++)
                    AnimatedContainer(
                      duration: AppMotion.base,
                      curve: AppMotion.curve,
                      margin: const EdgeInsets.only(right: 6),
                      height: 3,
                      width: i == _actual ? 28 : 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i == _actual
                            ? AppColors.gold
                            : AppColors.textPrimary.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 116,
              child: ValueListenableBuilder<double>(
                valueListenable: widget.offset,
                builder: (_, s, child) => Opacity(
                  opacity: (1 - s / 420).clamp(0.0, 1.0),
                  child: child,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LEGACY OF LUXURY · EST. MMXXVI',
                      style: kickerStyle(),
                    ),
                    const SizedBox(height: 18),
                    // FittedBox: en celulares angostos reduce la letra en vez de partir la palabra.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'UNDERLAW',
                        style: serifTitle(size: 62),
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Under the rules, only yours.',
                      style: GoogleFonts.jost(
                        fontSize: 18,
                        height: 1.4,
                        fontWeight: FontWeight.w300,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    UlButton(
                      label: 'Ver colección',
                      onPressed: widget.onVerColeccion,
                    ),
                    const SizedBox(height: 10),
                    UlButton.secondary(
                      label: 'Próximo drop',
                      onPressed: widget.onProximoDrop,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
