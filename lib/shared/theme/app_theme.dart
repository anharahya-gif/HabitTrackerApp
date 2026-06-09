import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Provider reaktif untuk mengatur mode tema aktif (Dark, Light, System)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// Model internal untuk menyimpan palet warna per preset tema.
class ThemeColors {
  final Color bg;
  final Color surface;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color defaultAccent;

  const ThemeColors({
    required this.bg,
    required this.surface,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.defaultAccent,
  });
}

/// Konfigurasi Tema UI Premium (Dark & Light Mode) untuk Habit Tracker App.
/// Mendukung preset warna dinamis, aksen kustom, dan font dari Google Fonts.
class AppTheme {
  AppTheme._();

  // Premium Color Palette - Calm Productivity Dark (Default)
  static const Color darkBg = Color(0xFF111318);
  static const Color darkSurface = Color(0xFF1A1D24);
  static const Color darkCard = Color(0xFF222632);
  static const Color darkBorder = Color(0xFF2E3342);
  static const Color darkTextPrimary = Color(0xFFE2E8F0);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static const Color lightBg = Color(0xFFF8FAFC); // Slate 50
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate 500

  // Status/Accent Colors - Calm Productivity Dark
  static const Color accentPrimary = Color(0xFF5AA9FF); // Blue Primary
  static const Color statusDone = Color(0xFF4ADE80); // Success (Green Done)
  static const Color statusSkipped = Color(0xFFFBBF24); // Warning (Yellow Skipped)
  static const Color statusMissed = Color(0xFFFB7185); // Danger (Pink/Red Missed)

  /// Map palet warna masing-masing preset tema
  static const Map<String, Map<Brightness, ThemeColors>> _presetColors = {
    'default': {
      Brightness.dark: ThemeColors(
        bg: darkBg,
        surface: darkSurface,
        card: darkCard,
        border: darkBorder,
        textPrimary: darkTextPrimary,
        textSecondary: darkTextSecondary,
        defaultAccent: accentPrimary,
      ),
      Brightness.light: ThemeColors(
        bg: lightBg,
        surface: lightCard,
        card: lightCard,
        border: lightBorder,
        textPrimary: lightTextPrimary,
        textSecondary: lightTextSecondary,
        defaultAccent: accentPrimary,
      ),
    },
    'warm_coffee': {
      Brightness.dark: ThemeColors(
        bg: Color(0xFF1F1A16),
        surface: Color(0xFF2C241E),
        card: Color(0xFF382F27),
        border: Color(0xFF453A30),
        textPrimary: Color(0xFFF5EFEB),
        textSecondary: Color(0xFFDFD3C3),
        defaultAccent: Color(0xFFB5835A),
      ),
      Brightness.light: ThemeColors(
        bg: Color(0xFFFDFBF7),
        surface: Color(0xFFFFFFFF),
        card: Color(0xFFEDE4DC),
        border: Color(0xFFDFD3C3),
        textPrimary: Color(0xFF3E2723),
        textSecondary: Color(0xFF8D6E63),
        defaultAccent: Color(0xFFB5835A),
      ),
    },
    'ocean_blue': {
      Brightness.dark: ThemeColors(
        bg: Color(0xFF0B132B),
        surface: Color(0xFF1C2541),
        card: Color(0xFF22305C),
        border: Color(0xFF3A506B),
        textPrimary: Color(0xFFE0E6ED),
        textSecondary: Color(0xFF9FB3C8),
        defaultAccent: Color(0xFF00B4D8),
      ),
      Brightness.light: ThemeColors(
        bg: Color(0xFFF0F4F8),
        surface: Color(0xFFFFFFFF),
        card: Color(0xFFD9E2EC),
        border: Color(0xFFBCCCDC),
        textPrimary: Color(0xFF102A43),
        textSecondary: Color(0xFF627D98),
        defaultAccent: Color(0xFF00B4D8),
      ),
    },
    'forest_green': {
      Brightness.dark: ThemeColors(
        bg: Color(0xFF0D1F10),
        surface: Color(0xFF1A331E),
        card: Color(0xFF25472A),
        border: Color(0xFF325C38),
        textPrimary: Color(0xFFE8F5E9),
        textSecondary: Color(0xFFB2DFDB),
        defaultAccent: Color(0xFF52B788),
      ),
      Brightness.light: ThemeColors(
        bg: Color(0xFFF1F7F2),
        surface: Color(0xFFFFFFFF),
        card: Color(0xFFE1ECE2),
        border: Color(0xFFBCCFBF),
        textPrimary: Color(0xFF1B5E20),
        textSecondary: Color(0xFF4CAF50),
        defaultAccent: Color(0xFF52B788),
      ),
    },
  };

  /// Memperoleh gaya font berdasarkan setelan kustom
  static TextStyle _getFontStyle(String fontFamily, TextStyle baseStyle) {
    switch (fontFamily) {
      case 'Inter':
        return GoogleFonts.inter(textStyle: baseStyle);
      case 'Poppins':
        return GoogleFonts.poppins(textStyle: baseStyle);
      case 'Outfit':
        return GoogleFonts.outfit(textStyle: baseStyle);
      case 'Lora':
        return GoogleFonts.lora(textStyle: baseStyle);
      default:
        return baseStyle; // System default font
    }
  }

  /// Membuat skema ThemeData dinamis
  static ThemeData buildTheme({
    required Brightness brightness,
    required String preset,
    required Color? customAccent,
    required String fontFamily,
  }) {
    final colors = _presetColors[preset]?[brightness] ?? _presetColors['default']![brightness]!;
    final accent = customAccent ?? colors.defaultAccent;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.bg,
      primaryColor: accent,
      colorScheme: brightness == Brightness.dark
          ? ColorScheme.dark(
              primary: accent,
              secondary: statusDone,
              surface: colors.surface,
              error: statusMissed,
              onPrimary: Colors.white,
              onSurface: colors.textPrimary,
            )
          : ColorScheme.light(
              primary: accent,
              secondary: statusDone,
              surface: colors.surface,
              error: statusMissed,
              onPrimary: Colors.white,
              onSurface: colors.textPrimary,
            ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: colors.border, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _getFontStyle(
          fontFamily,
          TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      textTheme: TextTheme(
        headlineLarge: _getFontStyle(fontFamily, TextStyle(color: colors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
        titleLarge: _getFontStyle(fontFamily, TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        bodyLarge: _getFontStyle(fontFamily, TextStyle(color: colors.textPrimary, fontSize: 16)),
        bodyMedium: _getFontStyle(fontFamily, TextStyle(color: colors.textSecondary, fontSize: 14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark ? colors.bg : Colors.white,
        labelStyle: TextStyle(color: colors.textSecondary),
        hintStyle: TextStyle(color: colors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  /// ThemeData static get untuk Light mode (hanya default fallback jika diperlukan)
  static ThemeData get lightTheme => buildTheme(
        brightness: Brightness.light,
        preset: 'default',
        customAccent: null,
        fontFamily: 'Default',
      );

  /// ThemeData static get untuk Dark mode (hanya default fallback jika diperlukan)
  static ThemeData get darkTheme => buildTheme(
        brightness: Brightness.dark,
        preset: 'default',
        customAccent: null,
        fontFamily: 'Default',
      );
}
