import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';

// Campo de formulario: alto 56, radio 14, fondo #0B0B0A. El label flota
// (15 px centrado → 11 px arriba) al enfocar o al tener texto. Foco: borde y
// label gold. Error: borde y label en error + mensaje de 12 px debajo.
class UlField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? error;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  const UlField({
    super.key,
    required this.controller,
    required this.label,
    this.error,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
  });

  @override
  State<UlField> createState() => _UlFieldState();
}

class _UlFieldState extends State<UlField> {
  final _focus = FocusNode();

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
    widget.controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(UlField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foco = _focus.hasFocus;
    final flota = foco || widget.controller.text.isNotEmpty;
    final error = widget.error;
    final borde = error != null
        ? AppColors.error
        : foco
        ? AppColors.gold
        : AppColors.border;
    final colorLabel = error != null
        ? AppColors.error
        : foco
        ? AppColors.gold
        : AppColors.textTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _focus.requestFocus,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: AppMotion.curve,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(color: borde),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: AppMotion.curve,
                  left: 16,
                  top: flota ? 9 : 18,
                  child: IgnorePointer(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: AppMotion.curve,
                      style: GoogleFonts.jost(
                        fontSize: flota ? 11 : 15,
                        letterSpacing: flota ? 1 : 0,
                        color: colorLabel,
                      ),
                      child: Text(widget.label),
                    ),
                  ),
                ),
                // El texto va pegado abajo (8 px) para no tapar el label flotante.
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 8,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    onChanged: widget.onChanged,
                    cursorColor: AppColors.gold,
                    style: GoogleFonts.jost(
                      fontSize: 15,
                      height: 1.2,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              error,
              style: GoogleFonts.jost(fontSize: 12, color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
