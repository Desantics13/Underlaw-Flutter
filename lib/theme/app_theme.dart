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
TextStyle serifTitle({double size = 48, FontWeight weight = FontWeight.w300, Color? color}) =>
    GoogleFonts.cormorantGaramond(
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
