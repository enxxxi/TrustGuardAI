// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Core
  static const bg = Color(0xFFF0F2F5);
  static const card = Color(0xFFFFFFFF);
  static const card2 = Color(0xFFF7F8FA);
  static const ink = Color(0xFF0D1117);
  static const ink2 = Color(0xFF3A4550);
  static const ink3 = Color(0xFF8A9AAA);
  static const border = Color(0xFFE4E8ED);

  // Brand
  static const accent = Color(0xFF0057FF);
  static const accentLight = Color(0xFFE8EEFF);

  // Status
  static const safe = Color(0xFF00B96B);
  static const safeLight = Color(0xFFE6F9F1);
  static const warn = Color(0xFFF59E0B);
  static const warnLight = Color(0xFFFEF3CD);
  static const danger = Color(0xFFEF2D56);
  static const dangerLight = Color(0xFFFDE8EC);

  // Dark (hero sections)
  static const dark1 = Color(0xFF0A1628);
  static const dark2 = Color(0xFF0D1F3C);
  static const darkCard = Color(0x12FFFFFF);
  static const darkBorder = Color(0x1AFFFFFF);
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
      );
}

// Reusable text styles
class AppText {
  static TextStyle display(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w800}) =>
      GoogleFonts.syne(fontSize: size, fontWeight: weight, color: color);

  static TextStyle body(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.dmSans(fontSize: size, fontWeight: weight, color: color);

  static TextStyle mono(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.dmMono(fontSize: size, fontWeight: weight, color: color);
}
