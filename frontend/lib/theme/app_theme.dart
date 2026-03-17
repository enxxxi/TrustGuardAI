// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const bg         = Color(0xFFF4F6F9);
  static const card       = Color(0xFFFFFFFF);
  static const card2      = Color(0xFFF8F9FB);
  static const card3      = Color(0xFFEDF0F4);

  // Text
  static const ink        = Color(0xFF111827);
  static const ink2       = Color(0xFF374151);
  static const ink3       = Color(0xFF6B7280);
  static const ink4       = Color(0xFF9CA3AF);
  static const border     = Color(0xFFE5E7EB);
  static const divider    = Color(0xFFF3F4F6);

  // Brand
  static const accent     = Color(0xFF1D4ED8);
  static const accentLight= Color(0xFFEFF6FF);
  static const accentMid  = Color(0xFF3B82F6);
  static const accentSoft = Color(0xFFDBEAFE);

  // Status
  static const safe       = Color(0xFF059669);
  static const safeLight  = Color(0xFFECFDF5);
  static const safeSoft   = Color(0xFFD1FAE5);
  static const warn       = Color(0xFFD97706);
  static const warnLight  = Color(0xFFFFFBEB);
  static const warnSoft   = Color(0xFFFDE68A);
  static const danger     = Color(0xFFDC2626);
  static const dangerLight= Color(0xFFFEF2F2);
  static const dangerSoft = Color(0xFFFECACA);

  // Dark hero
  static const dark1      = Color(0xFF0F172A);
  static const dark2      = Color(0xFF1E293B);
  static const dark3      = Color(0xFF334155);
  static const darkCard   = Color(0x0FFFFFFF);
  static const darkBorder = Color(0x18FFFFFF);
  static const darkText   = Color(0xFF94A3B8);
  static const darkText2  = Color(0xFF64748B);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accent,
      surface: AppColors.card,
    ),
    // Plus Jakarta Sans — optimized for readability on mobile
    textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
      bodyMedium: GoogleFonts.plusJakartaSans(color: AppColors.ink2),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.ink,
    ),
    dividerColor: AppColors.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      isDense: true,
    ),
  );
}

// ── Unified Text Styles ──────────────────────────────
// All fonts use Plus Jakarta Sans — clean, geometric, excellent at small sizes
class AppText {
  // Hero numbers, large titles
  static TextStyle h1(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w800}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: color, letterSpacing: -0.5, height: 1.15);

  // Section titles, card headers
  static TextStyle h2(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: color, letterSpacing: -0.3, height: 1.2);

  // Body text — comfortable reading
  static TextStyle body(double size, {Color color = AppColors.ink2, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: color, height: 1.55);

  // Labels, captions, supporting text
  static TextStyle label(double size, {Color color = AppColors.ink3, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.1, height: 1.4);

  // Monospace — amounts, IDs, codes only
  static TextStyle mono(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: weight, color: color, letterSpacing: -0.2);

  // Uppercase tags, badges
  static TextStyle tag(double size, {Color color = AppColors.ink3}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.8, height: 1.2);
}

// ── Shadows ──────────────────────────────────────────
class AppShadow {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x05000000), blurRadius: 24, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x06000000), blurRadius: 40, offset: Offset(0, 8)),
  ];
  static List<BoxShadow> colored(Color color) => [
    BoxShadow(color: color.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 4)),
    BoxShadow(color: color.withOpacity(0.10), blurRadius: 32, offset: const Offset(0, 8)),
  ];
}
