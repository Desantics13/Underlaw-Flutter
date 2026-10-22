import 'package:flutter/material.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';

enum UlButtonKind { primary, secondary, tertiary }

// Botones del sistema de diseño: principal (56), secundario (52) y terciario
// (44). Presionado = scale 0.98 + opacidad 0.86 (secundario: fondo gold 10%).
class UlButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed; // null = deshabilitado
  final UlButtonKind kind;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final bool iconTrailing;
  // Texto mientras carga; si es null solo se ve el spinner.
  final String? loadingLabel;

  const UlButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = UlButtonKind.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.iconTrailing = false,
    this.loadingLabel,
  });

  const UlButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.iconTrailing = false,
    this.loadingLabel,
  }) : kind = UlButtonKind.secondary;

  const UlButton.tertiary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.iconTrailing = false,
    this.loadingLabel,
  }) : kind = UlButtonKind.tertiary;

  @override
  State<UlButton> createState() => _UlButtonState();
}

class _UlButtonState extends State<UlButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  double get _height => switch (widget.kind) {
    UlButtonKind.primary => 56,
    UlButtonKind.secondary => 52,
    UlButtonKind.tertiary => 44,
  };

  void _set(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final kind = widget.kind;

    final Color fg;
    final Color? bg;
    final Border? border;
    switch (kind) {
      case UlButtonKind.primary:
        fg = disabled ? AppColors.textTertiary : AppColors.bgPrimary;
        bg = disabled ? AppColors.textA8 : AppColors.gold;
        border = null;
      case UlButtonKind.secondary:
        fg = disabled ? AppColors.textTertiary : AppColors.gold;
        bg = _pressed && _enabled ? AppColors.goldA10 : null;
        border = Border.all(
          color: disabled ? AppColors.border : AppColors.gold,
        );
      case UlButtonKind.tertiary:
        fg = disabled ? AppColors.textTertiary : AppColors.gold;
        bg = null;
        border = null;
    }

    final spinnerColor = kind == UlButtonKind.primary
        ? AppColors.bgPrimary
        : AppColors.gold;

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: spinnerColor,
              backgroundColor: spinnerColor.withValues(alpha: 0.25),
            ),
          ),
          if (widget.loadingLabel != null) const SizedBox(width: 12),
        ] else if (widget.icon != null &&
            !widget.iconTrailing &&
            kind != UlButtonKind.tertiary) ...[
          Icon(widget.icon, size: 18, color: fg),
          const SizedBox(width: 10),
        ],
        if (!widget.loading || widget.loadingLabel != null)
          Flexible(
            child: Text(
              (widget.loading ? widget.loadingLabel! : widget.label)
                  .toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: buttonTextStyle(color: fg),
            ),
          ),
        if (!widget.loading && widget.icon != null && widget.iconTrailing) ...[
          const SizedBox(width: 10),
          Icon(widget.icon, size: 18, color: fg),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _set(true) : null,
        onTapUp: _enabled ? (_) => _set(false) : null,
        onTapCancel: _enabled ? () => _set(false) : null,
        onTap: _enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed && kind != UlButtonKind.tertiary ? 0.98 : 1,
          duration: const Duration(milliseconds: 160),
          curve: AppMotion.curve,
          child: AnimatedOpacity(
            opacity: _pressed
                ? (kind == UlButtonKind.tertiary ? 0.6 : 0.86)
                : 1,
            duration: const Duration(milliseconds: 160),
            curve: AppMotion.curve,
            child: Container(
              height: _height,
              padding: EdgeInsets.symmetric(
                horizontal: kind == UlButtonKind.tertiary ? 8 : 24,
              ),
              decoration: BoxDecoration(
                color: bg,
                border: border,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
