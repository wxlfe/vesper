import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vesper/core/theme/theme_preference.dart';
import 'package:vesper/core/theme/theme_preference_service.dart';

void main() {
  test('reads Anglican liturgical preference by default', () async {
    SharedPreferences.setMockInitialValues({});
    const service = ThemeColorPreferenceService();

    final preference = await service.readThemeColorPreference();

    expect(
      preference,
      const ThemeColorPreference.liturgical(LiturgicalRite.anglican),
    );
  });

  test('legacy liturgical preference without rite reads as Anglican', () async {
    SharedPreferences.setMockInitialValues({'theme_color_mode': 'liturgical'});
    const service = ThemeColorPreferenceService();

    final preference = await service.readThemeColorPreference();

    expect(
      preference,
      const ThemeColorPreference.liturgical(LiturgicalRite.anglican),
    );
  });

  test('persists and reads liturgical rite options', () async {
    for (final rite in LiturgicalRite.values) {
      SharedPreferences.setMockInitialValues({});
      const service = ThemeColorPreferenceService();

      await service.writeThemeColorPreference(
        ThemeColorPreference.liturgical(rite),
      );

      expect(
        await service.readThemeColorPreference(),
        ThemeColorPreference.liturgical(rite),
      );
    }
  });

  test('persists and reads fixed theme option', () async {
    SharedPreferences.setMockInitialValues({});
    const service = ThemeColorPreferenceService();

    await service.writeThemeColorPreference(
      const ThemeColorPreference.fixed('purple'),
    );

    expect(
      await service.readThemeColorPreference(),
      const ThemeColorPreference.fixed('purple'),
    );
  });

  test('persists and reads custom theme color', () async {
    SharedPreferences.setMockInitialValues({});
    const service = ThemeColorPreferenceService();

    await service.writeThemeColorPreference(
      const ThemeColorPreference.custom(Color(0xff336699)),
    );

    expect(
      await service.readThemeColorPreference(),
      const ThemeColorPreference.custom(Color(0xff336699)),
    );
  });

  test('reads traditional theme style by default', () async {
    SharedPreferences.setMockInitialValues({});
    const service = ThemeStylePreferenceService();

    expect(await service.readThemeStyle(), ThemeStyle.traditional);
  });

  test('persists and reads contemporary theme style', () async {
    SharedPreferences.setMockInitialValues({});
    const service = ThemeStylePreferenceService();

    await service.writeThemeStyle(ThemeStyle.contemporary);

    expect(await service.readThemeStyle(), ThemeStyle.contemporary);
  });

  test('unknown theme style falls back to traditional', () async {
    SharedPreferences.setMockInitialValues({'theme_style': 'future-style'});
    const service = ThemeStylePreferenceService();

    expect(await service.readThemeStyle(), ThemeStyle.traditional);
  });
}
