import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Mismos tokens de color que src/index.css del proyecto web (--bg-primary,
// --gold, etc.), para que la app en Flutter se vea como la misma marca.
class AppColors {
  static const bgPrimary = Color(0xFF060606);
  static const bgSecondary = Color(0xFF0B0B0A);
  static const textPrimary = Color(0xFFF2F0EC);
  static const textSecondary = Color(0xFFCFC9BE);
  static const textTertiary = Color(0xFF9B958A);
  static const textMuted = Color(0xFF8B857A);
  static const gold = Color(0xFFC0A15B);
  static const success = Color(0xFF7FA87F);
  static const error = Color(0xFFB5726E);
  static const border = Color(0x1FF2F0EC);

  // Derivados del handoff (sin colores nuevos): mismos tonos con opacidad.
  static const goldA10 = Color(0x1AC0A15B); // chip/talla seleccionada
  static const goldA12 = Color(0x1FC0A15B); // indicador de la barra inferior
  static const goldA45 = Color(0x73C0A15B); // borde de FAQ abierta
  static const textA8 = Color(0x14F2F0EC); // fondo de botón deshabilitado
  static const textA25 = Color(0x40F2F0EC); // control deshabilitado
  static const placeholderA = Color(0xFF0E0E0D);
  static const placeholderB = Color(0xFF131312);
  static const shimmerHi = Color(0xFF1A1A18);
}

// Radios del sistema (cuadrícula 4/8, sin sombras).
class AppRadius {
  static const double thumb = 10;
  static const double field = 14; // tarjeta de imagen, chip de talla, campo
  static const double button = 16;
  static const double card = 20;
  static const double sheet = 24;
  static const double chip = 22;
  static const double nav = 32;
}

// Movimiento global: easeOutCubic, 250–400 ms.
class AppMotion {
  static const curve = Curves.easeOutCubic;
  static const fast = Duration(milliseconds: 220);
  static const base = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 400);
}

ThemeData buildUnderLawTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final sans = GoogleFonts.jostTextTheme(base.textTheme).apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bgPrimary,
    colorScheme: base.colorScheme.copyWith(
      surface: AppColors.bgPrimary,
      primary: AppColors.gold,
      secondary: AppColors.gold,
      error: AppColors.error,
    ),
    textTheme: sans,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    dividerColor: AppColors.border,
  );
}

// Título estilo "UNDERLAW": serif fina, mayúsculas, tracking amplio.
TextStyle serifTitle({
  double size = 48,
  FontWeight weight = FontWeight.w300,
  Color? color,
}) => GoogleFonts.cormorantGaramond(
  fontSize: size,
  fontWeight: weight,
  color: color ?? AppColors.textPrimary,
  letterSpacing: size * 0.05,
  height: 0.95,
);

TextStyle kickerStyle({Color? color}) => GoogleFonts.jost(
  fontSize: 11,
  fontWeight: FontWeight.w500,
  letterSpacing: 3.5,
  color: color ?? AppColors.gold,
);

// Label de sección ("TALLA", "CANTIDAD").
TextStyle labelStyle({Color? color}) => GoogleFonts.jost(
  fontSize: 11,
  fontWeight: FontWeight.w500,
  letterSpacing: 3,
  color: color ?? AppColors.textTertiary,
);

// Texto de botones: Jost 500 / 13 / 2.4 px, en mayúsculas.
TextStyle buttonTextStyle({Color? color}) => GoogleFonts.jost(
  fontSize: 13,
  fontWeight: FontWeight.w500,
  letterSpacing: 2.4,
  color: color ?? AppColors.bgPrimary,
);

// Precios en dorado con cifras tabulares.
TextStyle precioStyle({double size = 14, Color? color}) => GoogleFonts.jost(
  fontSize: size,
  fontWeight: FontWeight.w500,
  color: color ?? AppColors.gold,
  fontFeatures: const [FontFeature.tabularFigures()],
);
