import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';

// Toast centrado: entra en 300 ms (y+12 → 0) y dura 2.2 s. `bottom` lo ubica
// encima de la barra flotante (104) o de la barra fija del detalle (118).
class UlToast {
  static OverlayEntry? _actual;

  static void show(
    BuildContext context,
    String mensaje, {
    IconData icon = Icons.check_circle_outline,
    double bottom = 104,
  }) {
    _actual?.remove();
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastView(
        mensaje: mensaje,
        icon: icon,
        bottom: bottom,
        onDone: () {
          if (_actual == entry) _actual = null;
          entry.remove();
        },
      ),
    );
    _actual = entry;
    overlay.insert(entry);
  }
}

class _ToastView extends StatefulWidget {
  final String mensaje;
  final IconData icon;
  final double bottom;
  final VoidCallback onDone;

  const _ToastView({
    required this.mensaje,
    required this.icon,
    required this.bottom,
    required this.onDone,
  });

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _c.forward();
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    await _c.reverse();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = CurvedAnimation(parent: _c, curve: AppMotion.curve);
    return Positioned(
      left: 20,
      right: 20,
      bottom: widget.bottom + MediaQuery.paddingOf(context).bottom,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: t,
          builder: (_, child) => Opacity(
            opacity: t.value,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - t.value)),
              child: child,
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 18, color: AppColors.gold),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.mensaje,
                      style: GoogleFonts.jost(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
