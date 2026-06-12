import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vesper/core/theme/theme_preference.dart';
import 'package:vesper/core/theme/theme_preference_service.dart';

void main() {
  test('reads Anglican liturgical preference by default', () async {
    SharedPreferences.setMockInitialValues({});
    const service = ThemePreferenceService();

    final preference = await service.readThemePreference();

    expect(
      preference,
      const ThemePreference.liturgical(LiturgicalRite.anglican),
    );
  });

  test('legacy liturgical preference without rite reads as Anglican', () async {
    SharedPreferences.setMockInitialValues({'theme_color_mode': 'liturgical'});
    const service = ThemePreferenceService();

    final preference = await service.readThemePreference();

    expect(
      preference,
      const ThemePreference.liturgical(LiturgicalRite.anglican),
    );
  });

  test('persists and reads liturgical rite options', () async {
    for (final rite in LiturgicalRite.values) {
      SharedPreferences.setMockInitialValues({});
      const service = ThemePreferenceService();

      await service.writeThemePreference(ThemePreference.liturgical(rite));

      expect(
        await service.readThemePreference(),
        ThemePreference.liturgical(rite),
      );
    }
  });

  test('persists and reads fixed theme option', () async {
    SharedPreferences.setMockInitialValues({});
    const service = ThemePreferenceService();

    await service.writeThemePreference(const ThemePreference.fixed('purple'));

    expect(
      await service.readThemePreference(),
      const ThemePreference.fixed('purple'),
    );
  });

  test('persists and reads custom theme color', () async {
    SharedPreferences.setMockInitialValues({});
    const service = ThemePreferenceService();

    await service.writeThemePreference(
      const ThemePreference.custom(Color(0xff336699)),
    );

    expect(
      await service.readThemePreference(),
      const ThemePreference.custom(Color(0xff336699)),
    );
  });
}
