import 'package:flutter/material.dart';

class AppTheme {
  static const _lightBackground = Color(0xfff4f6f0);
  static const _lightSurface = Color(0xffffffff);
  static const _lightText = Color(0xff242b24);
  static const _lightSecondary = Color(0xff6a7267);
  static const _lightAccent = Color(0xff5f725b);

  static const _darkBackground = Color(0xff111610);
  static const _darkSurface = Color(0xff1b211a);
  static const _darkText = Color(0xffedf2ea);
  static const _darkSecondary = Color(0xffa9b1a5);
  static const _darkAccent = Color(0xffa3b39d);

  static ThemeData get light => _theme(
    brightness: Brightness.light,
    background: _lightBackground,
    surface: _lightSurface,
    primaryText: _lightText,
    secondaryText: _lightSecondary,
    accent: _lightAccent,
  );

  static ThemeData get dark => _theme(
    brightness: Brightness.dark,
    background: _darkBackground,
    surface: _darkSurface,
    primaryText: _darkText,
    secondaryText: _darkSecondary,
    accent: _darkAccent,
  );

  static ThemeData _theme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color primaryText,
    required Color secondaryText,
    required Color accent,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: accent,
      surface: surface,
    ).copyWith(primary: accent, onSurface: primaryText);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontSize: 30,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: primaryText,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: primaryText,
        ),
        bodyLarge: TextStyle(fontSize: 17, height: 1.6, color: primaryText),
        bodyMedium: TextStyle(fontSize: 15, height: 1.5, color: secondaryText),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: accent,
          foregroundColor: brightness == Brightness.light
              ? Colors.white
              : _darkBackground,
        ),
      ),
    );
  }
}
