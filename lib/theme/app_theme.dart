import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum BoardThemeType {
  cyberpunk(
    name: 'Cyberpunk Neon',
    lightSquare: Color(0xFF334155),
    darkSquare: Color(0xFF0F172A),
    accentColor: Color(0xFF00F0FF),
    borderColor: Color(0xFF00F0FF),
  ),
  emerald(
    name: 'Emerald Tournament',
    lightSquare: Color(0xFFE2E8F0),
    darkSquare: Color(0xFF059669),
    accentColor: Color(0xFF10B981),
    borderColor: Color(0xFF10B981),
  ),
  wood(
    name: 'Classic Walnut',
    lightSquare: Color(0xFFF0D9B5),
    darkSquare: Color(0xFFB58863),
    accentColor: Color(0xFFEAB308),
    borderColor: Color(0xFF854D0E),
  ),
  midnight(
    name: 'Midnight Obsidian',
    lightSquare: Color(0xFF1E293B),
    darkSquare: Color(0xFF090D16),
    accentColor: Color(0xFF8B5CF6),
    borderColor: Color(0xFF6366F1),
  );

  final String name;
  final Color lightSquare;
  final Color darkSquare;
  final Color accentColor;
  final Color borderColor;

  const BoardThemeType({
    required this.name,
    required this.lightSquare,
    required this.darkSquare,
    required this.accentColor,
    required this.borderColor,
  });
}

class AppTheme {
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF131B2E);
  static const Color cardDark = Color(0xFF1E293B);
  
  static const Color primaryNeon = Color(0xFF00F0FF); // Cyan
  static const Color secondaryNeon = Color(0xFF10B981); // Emerald
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color alertRed = Color(0xFFEF4444);
  static const Color textMuted = Color(0xFF94A3B8);

  static BoardThemeType activeBoardTheme = BoardThemeType.cyberpunk;

  // Highlights
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
