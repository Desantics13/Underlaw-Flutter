import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/core/widgets/striped_placeholder.dart';
import 'package:underlaw_flutter/core/widgets/ul_button.dart';

// Hero a pantalla completa. La foto se mueve a 0.4× del scroll (parallax) y el
// contenido se desvanece en los primeros 420 px. La zona rayada es el
// placeholder de la foto editorial (9:19.5).
class HomeHero extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: offset,
              builder: (_, s, child) => Positioned(
                top: -40 + s * 0.4,
                left: 0,
                right: 0,
                height: height + 80,
                child: child!,
              ),
              child: StripedPlaceholder(
                child: Padding(
                  padding: const EdgeInsets.only(top: 300),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      'FOTO EDITORIAL · HERO 9:19.5',
                      style: GoogleFonts.robotoMono(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00060606),
                    Color(0xD1060606),
                    AppColors.bgPrimary,
                  ],
                  stops: [0.30, 0.66, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 116,
              child: ValueListenableBuilder<double>(
                valueListenable: offset,
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
                    UlButton(label: 'Ver colección', onPressed: onVerColeccion),
                    const SizedBox(height: 10),
                    UlButton.secondary(
                      label: 'Próximo drop',
                      onPressed: onProximoDrop,
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
