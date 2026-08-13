import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF131B2E);
  static const Color cardDark = Color(0xFF1E293B);
  
  static const Color primaryNeon = Color(0xFF00F0FF); // Cyan
  static const Color secondaryNeon = Color(0xFF10B981); // Emerald
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color alertRed = Color(0xFFEF4444);
  static const Color textMuted = Color(0xFF94A3B8);

  // Board themes
  static const Color lightSquareClassic = Color(0xFFE2E8F0);
  static const Color darkSquareClassic = Color(0xFF475569);

  static const Color lightSquareCyber = Color(0xFF334155);
  static const Color darkSquareCyber = Color(0xFF0F172A);

  static const Color lightSquareEmerald = Color(0xFFE2E8F0);
  static const Color darkSquareEmerald = Color(0xFF059669);

  static const Color highlightMove = Color(0x6600F0FF);
  static const Color highlightBestMove = Color(0x8010B981);
  static const Color highlightCheck = Color(0x80EF4444);

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
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      cardTheme: CardTheme(
        color: cardDark,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
