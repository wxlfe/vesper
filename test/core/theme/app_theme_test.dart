import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/theme/app_theme.dart';
import 'package:vesper/core/theme/theme_preference.dart';

void main() {
  test('light theme uses the manuscript icon palette', () {
    final theme = AppTheme.lightForDate(DateTime(2026, 6, 4));

    expect(theme.scaffoldBackgroundColor, const Color(0xfffbf3df));
    expect(theme.cardTheme.color, const Color(0xfffffaf0));
    expect(theme.colorScheme.primary, const Color(0xff208070));
    expect(theme.colorScheme.tertiary, const Color(0xff583070));
    expect(theme.textTheme.bodyLarge?.color, const Color(0xff241c14));
    expect(theme.textTheme.bodyMedium?.color, const Color(0xff6f5f4a));
  });

  test('dark theme uses accessible icon palette variants', () {
    final theme = AppTheme.darkForDate(DateTime(2026, 6, 4));

    expect(theme.scaffoldBackgroundColor, const Color(0xff19130d));
    expect(theme.cardTheme.color, const Color(0xff241b12));
    expect(theme.colorScheme.primary, const Color(0xff8eb28b));
    expect(theme.colorScheme.tertiary, const Color(0xffa78bd0));
    expect(theme.textTheme.bodyLarge?.color, const Color(0xfff6ead1));
    expect(theme.textTheme.bodyMedium?.color, const Color(0xffc9b894));
  });

  test('light theme primary follows the liturgical season', () {
    expect(
      AppTheme.lightForDate(DateTime(2026, 11, 29)).colorScheme.primary,
      const Color(0xff583070),
    );
    expect(
      AppTheme.lightForDate(DateTime(2026, 12, 25)).colorScheme.primary,
      const Color(0xffb58a32),
    );
    expect(
      AppTheme.lightForDate(DateTime(2026, 1, 6)).colorScheme.primary,
      const Color(0xff294f7a),
    );
    expect(
      AppTheme.lightForDate(DateTime(2026, 2, 18)).colorScheme.primary,
      const Color(0xff583070),
    );
    expect(
      AppTheme.lightForDate(DateTime(2026, 3, 29)).colorScheme.primary,
      const Color(0xff583070),
    );
    expect(
      AppTheme.lightForDate(DateTime(2026, 4, 3)).colorScheme.primary,
      const Color(0xff151515),
    );
    expect(
      AppTheme.lightForDate(DateTime(2026, 4, 5)).colorScheme.primary,
      const Color(0xffb58a32),
    );
    expect(
      AppTheme.lightForDate(DateTime(2026, 5, 24)).colorScheme.primary,
      const Color(0xff8f2f2f),
    );
  });

  test('seasonal primary foreground chooses accessible contrast', () {
    expect(
      AppTheme.lightForDate(DateTime(2026, 12, 25)).colorScheme.onPrimary,
      const Color(0xff241c14),
    );
    expect(
      AppTheme.lightForDate(DateTime(2026, 4, 3)).colorScheme.onPrimary,
      Colors.white,
    );
    expect(
      AppTheme.darkForDate(DateTime(2026, 4, 3)).colorScheme.onPrimary,
      const Color(0xff19130d),
    );
  });

  test('dark theme primary follows accessible liturgical variants', () {
    expect(
      AppTheme.darkForDate(DateTime(2026, 11, 29)).colorScheme.primary,
      const Color(0xffa78bd0),
    );
    expect(
      AppTheme.darkForDate(DateTime(2026, 12, 25)).colorScheme.primary,
      const Color(0xffd1aa55),
    );
    expect(
      AppTheme.darkForDate(DateTime(2026, 1, 6)).colorScheme.primary,
      const Color(0xff8fb4d8),
    );
    expect(
      AppTheme.darkForDate(DateTime(2026, 4, 3)).colorScheme.primary,
      const Color(0xff9a9a9a),
    );
    expect(
      AppTheme.darkForDate(DateTime(2026, 5, 24)).colorScheme.primary,
      const Color(0xffc46a60),
    );
  });

  test(
    'theme preference defaults to the Anglican liturgical calendar color',
    () {
      final theme = AppTheme.lightForPreference(
        const ThemePreference.liturgical(),
        date: DateTime(2026, 6, 4),
      );

      expect(theme.colorScheme.primary, const Color(0xff208070));
    },
  );

  test('liturgical rite preferences resolve their current color', () {
    expect(
      AppTheme.lightForPreference(
        const ThemePreference.liturgical(LiturgicalRite.roman),
        date: DateTime(2026, 3, 1),
      ).colorScheme.primary,
      const Color(0xff583070),
    );
    expect(
      AppTheme.lightForPreference(
        const ThemePreference.liturgical(LiturgicalRite.anglican),
        date: DateTime(2026, 5, 24),
      ).colorScheme.primary,
      const Color(0xff8f2f2f),
    );
    expect(
      AppTheme.lightForPreference(
        const ThemePreference.liturgical(LiturgicalRite.lutheran),
        date: DateTime(2026, 12, 25),
      ).colorScheme.primary,
      const Color(0xffb58a32),
    );
  });

  test('Byzantine rite follows Orthodox movable seasons and feast colors', () {
    expect(
      AppTheme.lightForLiturgicalRite(
        LiturgicalRite.byzantine,
        DateTime(2026, 3, 2),
      ).colorScheme.primary,
      const Color(0xff583070),
    );
    expect(
      AppTheme.lightForLiturgicalRite(
        LiturgicalRite.byzantine,
        DateTime(2026, 4, 10),
      ).colorScheme.primary,
      const Color(0xff151515),
    );
    expect(
      AppTheme.lightForLiturgicalRite(
        LiturgicalRite.byzantine,
        DateTime(2026, 4, 12),
      ).colorScheme.primary,
      const Color(0xffb58a32),
    );
    expect(
      AppTheme.lightForLiturgicalRite(
        LiturgicalRite.byzantine,
        DateTime(2026, 5, 31),
      ).colorScheme.primary,
      const Color(0xff208070),
    );
    expect(
      AppTheme.lightForLiturgicalRite(
        LiturgicalRite.byzantine,
        DateTime(2026, 8, 15),
      ).colorScheme.primary,
      const Color(0xff294f7a),
    );
  });

  test('Russian rite uses Julian fixed feasts with Orthodox Pascha', () {
    expect(
      AppTheme.lightForLiturgicalRite(
        LiturgicalRite.russian,
        DateTime(2026, 1, 7),
      ).colorScheme.primary,
      const Color(0xffb58a32),
    );
    expect(
      AppTheme.lightForLiturgicalRite(
        LiturgicalRite.russian,
        DateTime(2026, 4, 7),
      ).colorScheme.primary,
      const Color(0xff294f7a),
    );
    expect(
      AppTheme.lightForLiturgicalRite(
        LiturgicalRite.russian,
        DateTime(2026, 4, 12),
      ).colorScheme.primary,
      const Color(0xffb58a32),
    );
  });

  test('Coptic rite follows Coptic feasts fasts and Pascha color rules', () {
    expect(
      AppTheme.lightForLiturgicalRite(
        LiturgicalRite.coptic,
        DateTime(2026, 1, 7),
      ).colorScheme.primary,
      const Color(0xffb58a32),
    );
    expect(
      AppTheme.lightForLiturgicalRite(
        LiturgicalRite.coptic,
        DateTime(2026, 3, 2),
      ).colorScheme.primary,
      const Color(0xff583070),
    );
    expect(
      AppTheme.lightForLiturgicalRite(
        LiturgicalRite.coptic,
        DateTime(2026, 4, 10),
      ).colorScheme.primary,
      const Color(0xff151515),
    );
    expect(
      AppTheme.lightForLiturgicalRite(
        LiturgicalRite.coptic,
        DateTime(2026, 5, 31),
      ).colorScheme.primary,
      const Color(0xff8f2f2f),
    );
  });

  test('fixed theme preference resolves built in liturgical colors', () {
    final theme = AppTheme.lightForPreference(
      const ThemePreference.fixed('purple'),
      date: DateTime(2026, 6, 4),
    );

    expect(theme.colorScheme.primary, const Color(0xff583070));
  });

  test('custom theme preference uses selected primary color', () {
    const custom = Color(0xff336699);
    final theme = AppTheme.lightForPreference(
      const ThemePreference.custom(custom),
      date: DateTime(2026, 6, 4),
    );

    expect(theme.colorScheme.primary, custom);
  });
}
