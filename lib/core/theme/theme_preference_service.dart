import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vesper/core/theme/theme_preference.dart';

class ThemePreferenceService {
  const ThemePreferenceService();

  static const _modeKey = 'theme_color_mode';
  static const _liturgicalRiteKey = 'theme_liturgical_rite';
  static const _fixedOptionIdKey = 'theme_fixed_option_id';
  static const _customColorKey = 'theme_custom_color';

  Future<ThemePreference> readThemePreference() async {
    final preferences = await SharedPreferences.getInstance();
    final mode = preferences.getString(_modeKey);
    return switch (mode) {
      'liturgical' => ThemePreference.liturgical(
        _riteForId(preferences.getString(_liturgicalRiteKey)),
      ),
      'fixed' => ThemePreference.fixed(
        preferences.getString(_fixedOptionIdKey) ?? 'green',
      ),
      'custom' => ThemePreference.custom(
        Color(preferences.getInt(_customColorKey) ?? 0xff208070),
      ),
      _ => const ThemePreference.liturgical(LiturgicalRite.anglican),
    };
  }

  Future<void> writeThemePreference(ThemePreference preference) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_modeKey, preference.mode.name);
    switch (preference.mode) {
      case ThemeColorMode.liturgical:
        await preferences.setString(
          _liturgicalRiteKey,
          (preference.liturgicalRite ?? LiturgicalRite.anglican).name,
        );
        await preferences.remove(_fixedOptionIdKey);
        await preferences.remove(_customColorKey);
      case ThemeColorMode.fixed:
        await preferences.setString(
          _fixedOptionIdKey,
          preference.fixedOptionId ?? 'green',
        );
        await preferences.remove(_liturgicalRiteKey);
        await preferences.remove(_customColorKey);
      case ThemeColorMode.custom:
        await preferences.setInt(
          _customColorKey,
          preference.customColor?.toARGB32() ?? 0xff208070,
        );
        await preferences.remove(_liturgicalRiteKey);
        await preferences.remove(_fixedOptionIdKey);
    }
  }

  LiturgicalRite _riteForId(String? id) {
    return LiturgicalRite.values.firstWhere(
      (rite) => rite.name == id,
      orElse: () => LiturgicalRite.anglican,
    );
  }
}
