import 'package:flutter/material.dart';
import 'package:vesper/core/theme/liturgical_season.dart';

class AppTheme {
  static const _lightBackground = Color(0xfffbf3df);
  static const _lightSurface = Color(0xfffffaf0);
  static const _lightRaisedSurface = Color(0xfff6ead1);
  static const _lightText = Color(0xff241c14);
  static const _lightSecondary = Color(0xff6f5f4a);
  static const _lightMuted = Color(0xff8c7a61);
  static const _lightDivider = Color(0xffdfcfab);
  static const _lightGold = Color(0xffb58a32);
  static const _lightIconGreen = Color(0xff208070);
  static const _lightIconPurple = Color(0xff583070);
  static const _lightPentecost = Color(0xff8f2f2f);
  static const _lightGoodFriday = Color(0xff151515);
  static const _lightLapis = Color(0xff294f7a);
  static const _lightMalachite = Color(0xff4f6f53);

  static const _darkBackground = Color(0xff19130d);
  static const _darkSurface = Color(0xff241b12);
  static const _darkRaisedSurface = Color(0xff302418);
  static const _darkText = Color(0xfff6ead1);
  static const _darkSecondary = Color(0xffc9b894);
  static const _darkMuted = Color(0xffa8926c);
  static const _darkDivider = Color(0xff4a3826);
  static const _darkGold = Color(0xffd1aa55);
  static const _darkIconGreen = Color(0xff8eb28b);
  static const _darkIconPurple = Color(0xffa78bd0);
  static const _darkPentecost = Color(0xffc46a60);
  static const _darkGoodFriday = Color(0xff9a9a9a);
  static const _darkLapis = Color(0xff8fb4d8);
  static const _darkMalachite = Color(0xff8eb28b);

  static ThemeData get light => lightForDate(DateTime.now());

  static ThemeData get dark => darkForDate(DateTime.now());

  static ThemeData lightForDate(DateTime date) {
    return lightForSeason(liturgicalSeasonFor(date));
  }

  static ThemeData darkForDate(DateTime date) {
    return darkForSeason(liturgicalSeasonFor(date));
  }

  static ThemeData lightForSeason(LiturgicalSeason season) => _theme(
    brightness: Brightness.light,
    background: _lightBackground,
    surface: _lightSurface,
    raisedSurface: _lightRaisedSurface,
    primaryText: _lightText,
    secondaryText: _lightSecondary,
    mutedText: _lightMuted,
    divider: _lightDivider,
    gold: _lightGold,
    primaryAccent: _lightPrimaryForSeason(season),
    purple: _lightIconPurple,
    lapis: _lightLapis,
    malachite: _lightMalachite,
  );

  static ThemeData darkForSeason(LiturgicalSeason season) => _theme(
    brightness: Brightness.dark,
    background: _darkBackground,
    surface: _darkSurface,
    raisedSurface: _darkRaisedSurface,
    primaryText: _darkText,
    secondaryText: _darkSecondary,
    mutedText: _darkMuted,
    divider: _darkDivider,
    gold: _darkGold,
    primaryAccent: _darkPrimaryForSeason(season),
    purple: _darkIconPurple,
    lapis: _darkLapis,
    malachite: _darkMalachite,
  );

  static Color _lightPrimaryForSeason(LiturgicalSeason season) {
    return switch (season) {
      LiturgicalSeason.advent ||
      LiturgicalSeason.lent ||
      LiturgicalSeason.holyWeek => _lightIconPurple,
      LiturgicalSeason.christmas || LiturgicalSeason.easter => _lightGold,
      LiturgicalSeason.epiphany => _lightLapis,
      LiturgicalSeason.goodFriday => _lightGoodFriday,
      LiturgicalSeason.pentecost => _lightPentecost,
      LiturgicalSeason.ordinary => _lightIconGreen,
    };
  }

  static Color _darkPrimaryForSeason(LiturgicalSeason season) {
    return switch (season) {
      LiturgicalSeason.advent ||
      LiturgicalSeason.lent ||
      LiturgicalSeason.holyWeek => _darkIconPurple,
      LiturgicalSeason.christmas || LiturgicalSeason.easter => _darkGold,
      LiturgicalSeason.epiphany => _darkLapis,
      LiturgicalSeason.goodFriday => _darkGoodFriday,
      LiturgicalSeason.pentecost => _darkPentecost,
      LiturgicalSeason.ordinary => _darkIconGreen,
    };
  }

  static ThemeData _theme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color raisedSurface,
    required Color primaryText,
    required Color secondaryText,
    required Color mutedText,
    required Color divider,
    required Color gold,
    required Color primaryAccent,
    required Color purple,
    required Color lapis,
    required Color malachite,
  }) {
    final onPrimary = _bestOnPrimary(
      primaryAccent,
      brightness == Brightness.light ? _lightText : _darkBackground,
    );
    final colorScheme =
        ColorScheme.fromSeed(
          brightness: brightness,
          seedColor: primaryAccent,
          surface: surface,
        ).copyWith(
          primary: primaryAccent,
          onPrimary: onPrimary,
          primaryContainer: raisedSurface,
          onPrimaryContainer: primaryText,
          secondary: gold,
          onSecondary: brightness == Brightness.light
              ? _lightText
              : _darkBackground,
          secondaryContainer: raisedSurface,
          onSecondaryContainer: primaryText,
          tertiary: purple,
          onTertiary: Colors.white,
          tertiaryContainer: brightness == Brightness.light
              ? const Color(0xffe8dcc2)
              : const Color(0xff392a1c),
          onTertiaryContainer: primaryText,
          surface: surface,
          surfaceContainerHighest: raisedSurface,
          onSurface: primaryText,
          onSurfaceVariant: secondaryText,
          outline: divider,
          outlineVariant: divider,
          error: brightness == Brightness.light
              ? const Color(0xff7f2525)
              : const Color(0xffffb4ab),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Georgia',
      dividerColor: divider,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: primaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 24,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: primaryText,
        ),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 34,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: primaryText,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 24,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: primaryText,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 18,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: primaryText,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          height: 1.25,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: primaryAccent,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 18,
          height: 1.65,
          color: primaryText,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 15,
          height: 1.55,
          color: secondaryText,
        ),
        bodySmall: TextStyle(fontSize: 13, height: 1.45, color: mutedText),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: divider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: gold, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: primaryAccent,
          foregroundColor: onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryAccent,
          side: BorderSide(color: divider),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryAccent,
        foregroundColor: onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: IconThemeData(color: secondaryText),
    );
  }

  static Color _bestOnPrimary(Color primary, Color darkCandidate) {
    final whiteContrast = _contrastRatio(primary, Colors.white);
    final darkContrast = _contrastRatio(primary, darkCandidate);
    return darkContrast > whiteContrast ? darkCandidate : Colors.white;
  }

  static double _contrastRatio(Color first, Color second) {
    final firstLuminance = first.computeLuminance();
    final secondLuminance = second.computeLuminance();
    final lighter = firstLuminance > secondLuminance
        ? firstLuminance
        : secondLuminance;
    final darker = firstLuminance > secondLuminance
        ? secondLuminance
        : firstLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }
}
