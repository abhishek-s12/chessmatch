import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum BoardThemeType {
  walnut(
    name: 'Tournament Walnut',
    lightSquare: Color(0xFFEEEED2),
    darkSquare: Color(0xFFB58863),
    accentColor: Color(0xFFF59E0B),
    borderColor: Color(0xFF78350F),
    coordinateLight: Color(0xFFB58863),
    coordinateDark: Color(0xFFEEEED2),
  ),
  emerald(
    name: 'Official Emerald',
    lightSquare: Color(0xFFEBECD0),
    darkSquare: Color(0xFF739552),
    accentColor: Color(0xFF22C55E),
    borderColor: Color(0xFF3F6212),
    coordinateLight: Color(0xFF739552),
    coordinateDark: Color(0xFFEBECD0),
  ),
  obsidian(
    name: 'Obsidian Glass',
    lightSquare: Color(0xFF334155),
    darkSquare: Color(0xFF0F172A),
    accentColor: Color(0xFF38BDF8),
    borderColor: Color(0xFF1E293B),
    coordinateLight: Color(0xFF64748B),
    coordinateDark: Color(0xFF94A3B8),
  ),
  cyber(
    name: 'Cyberpunk Neo',
    lightSquare: Color(0xFF1E293B),
    darkSquare: Color(0xFF020617),
    accentColor: Color(0xFF06B6D4),
    borderColor: Color(0xFF06B6D4),
    coordinateLight: Color(0xFF06B6D4),
    coordinateDark: Color(0xFF67E8F9),
  ),
  marble(
    name: 'Alabaster Marble',
    lightSquare: Color(0xFFF8FAFC),
    darkSquare: Color(0xFF475569),
    accentColor: Color(0xFFA855F7),
    borderColor: Color(0xFF334155),
    coordinateLight: Color(0xFF475569),
    coordinateDark: Color(0xFFF8FAFC),
  );

  final String name;
  final Color lightSquare;
  final Color darkSquare;
  final Color accentColor;
  final Color borderColor;
  final Color coordinateLight;
  final Color coordinateDark;

  const BoardThemeType({
    required this.name,
    required this.lightSquare,
    required this.darkSquare,
    required this.accentColor,
    required this.borderColor,
    required this.coordinateLight,
    required this.coordinateDark,
  });
}

class AppTheme {
  // Deep luxury dark palette
  static const Color backgroundDark = Color(0xFF080C14);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color cardDarkElevated = Color(0xFF243048);

  // Modern Accent Tones
  static const Color primaryNeon = Color(0xFF38BDF8); // Electric Sky Blue
  static const Color secondaryNeon = Color(0xFF22C55E); // Crisp Emerald
  static const Color accentGold = Color(0xFFF59E0B); // Amber Gold
  static const Color accentPurple = Color(0xFFA855F7); // Royalty Purple
  static const Color alertRed = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);

  // Chess.com standard classification colors
  static const Color brilliantCyan = Color(0xFF1BACA6);
  static const Color greatBlue = Color(0xFF5C8BB0);
  static const Color bestGreen = Color(0xFF81B64C);
  static const Color bookAmber = Color(0xFFC3996B);
  static const Color inaccuracyGold = Color(0xFFF7C631);
  static const Color mistakeOrange = Color(0xFFE6912C);
  static const Color missedWinCrimson = Color(0xFFDB5353);
  static const Color blunderRed = Color(0xFFFA412D);

  static BoardThemeType activeBoardTheme = BoardThemeType.emerald;

  // Highlights
  static const Color highlightMove = Color(0x7338BDF8);
  static const Color highlightBestMove = Color(0x8C22C55E);
  static const Color highlightCheck = Color(0x99EF4444);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryNeon,
      colorScheme: const ColorScheme.dark(
        primary: primaryNeon,
        secondary: secondaryNeon,
        surface: surfaceDark,
        error: alertRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
    );
  }
}
