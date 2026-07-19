import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Colours (Design.md §3) ────────────────────────────────────────────────
  static const Color primary      = Color(0xFF2563EB);
  static const Color primaryDark  = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFDBEAFE);

  static const Color bgMain      = Color(0xFFFFFFFF);
  static const Color bgSecondary = Color(0xFFF7F8FC);
  static const Color bgCard      = Color(0xFFFFFFFF);
  static const Color bgSection   = Color(0xFFEFF6FF);

  static const Color textHeading   = Color(0xFF0F172A);
  static const Color textBody      = Color(0xFF374151);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled  = Color(0xFFCBD5E1);

  static const Color divider = Color(0xFFE2E8F0);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // ─── Spacing — 8pt grid (Design.md §5) ────────────────────────────────────
  static const double sp4  = 4;
  static const double sp8  = 8;
  static const double sp12 = 12;
  static const double sp16 = 16;
  static const double sp24 = 24;
  static const double sp32 = 32;
  static const double sp48 = 48;
  static const double sp64 = 64;

  // ─── Border Radii (Design.md §6) ──────────────────────────────────────────
  static const double radiusButton = 12;
  static const double radiusCard   = 16;
  static const double radiusInput  = 12;
  static const double radiusSheet  = 24;

  // ─── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      surface: bgMain,
      onSurface: textHeading,
    ),
    scaffoldBackgroundColor: bgMain,
    fontFamily: GoogleFonts.inter().fontFamily,

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: bgMain,
      foregroundColor: textHeading,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: divider,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: textHeading, letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: textHeading, size: 24),
    ),

    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton)),
        textStyle: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),

    // OutlinedButton
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton)),
        textStyle: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    // TextField / InputDecoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgSecondary,
      hintStyle: GoogleFonts.inter(
          color: textDisabled, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: sp16, vertical: sp16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: error),
      ),
    ),

    // Card
    cardTheme: CardThemeData(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
        side: const BorderSide(color: divider),
      ),
    ),

    // BottomNavigationBar
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bgMain,
      indicatorColor: primaryLight,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700, color: primary);
        }
        return GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primary, size: 24);
        }
        return const IconThemeData(color: textSecondary, size: 24);
      }),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: divider, thickness: 1, space: 0),

    // Typography (Design.md §4)
    textTheme: TextTheme(
      displayLarge  : GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700,
          color: textHeading, letterSpacing: -0.5),
      displayMedium : GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700,
          color: textHeading, letterSpacing: -0.4),
      displaySmall  : GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700,
          color: textHeading, letterSpacing: -0.3),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700,
          color: textHeading),
      titleLarge    : GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700,
          color: textHeading),
      titleMedium   : GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600,
          color: textHeading),
      labelLarge    : GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
          color: textHeading),
      bodyLarge     : GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400,
          color: textBody),
      bodyMedium    : GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400,
          color: textSecondary),
      bodySmall     : GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400,
          color: textSecondary),
    ),
  );
}
