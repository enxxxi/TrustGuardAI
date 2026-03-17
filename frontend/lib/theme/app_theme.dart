// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg        = Color(0xFFF0F2F5);
  static const card      = Color(0xFFFFFFFF);
  static const card2     = Color(0xFFF7F8FA);
  static const card3     = Color(0xFFEEF1F5);
  static const ink       = Color(0xFF0D1117);
  static const ink2      = Color(0xFF3A4550);
  static const ink3      = Color(0xFF8A9AAA);
  static const border    = Color(0xFFE4E8ED);
  static const accent    = Color(0xFF0057FF);
  static const accentLight = Color(0xFFE8EEFF);
  static const accentMid   = Color(0xFF3D7BFF);
  static const safe      = Color(0xFF00B96B);
  static const safeLight = Color(0xFFE6F9F1);
  static const safeMid   = Color(0xFF00D97E);
  static const warn      = Color(0xFFF59E0B);
  static const warnLight = Color(0xFFFEF3CD);
  static const danger    = Color(0xFFEF2D56);
  static const dangerLight = Color(0xFFFDE8EC);
  static const dark1     = Color(0xFF0A1628);
  static const dark2     = Color(0xFF0D1F3C);
  static const dark3     = Color(0xFF162035);
  static const darkCard  = Color(0x12FFFFFF);
  static const darkBorder= Color(0x1AFFFFFF);
  static const darkText  = Color(0x66FFFFFF);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accent,
      surface: AppColors.card,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.ink,
    ),
    dividerColor: AppColors.border,
  );
}

class AppText {
  static TextStyle display(double size,
      {Color color = AppColors.ink, FontWeight weight = FontWeight.w800}) =>
      GoogleFonts.syne(fontSize: size, fontWeight: weight, color: color, height: 1.2);

  static TextStyle body(double size,
      {Color color = AppColors.ink, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.dmSans(fontSize: size, fontWeight: weight, color: color, height: 1.4);

  static TextStyle mono(double size,
      {Color color = AppColors.ink, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.dmMono(fontSize: size, fontWeight: weight, color: color);
}
