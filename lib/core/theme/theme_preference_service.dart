import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vesper/core/theme/theme_preference.dart';

class ThemeColorPreferenceService {
  const ThemeColorPreferenceService();

  static const _modeKey = 'theme_color_mode';
  static const _liturgicalRiteKey = 'theme_liturgical_rite';
  static const _fixedOptionIdKey = 'theme_fixed_option_id';
  static const _customColorKey = 'theme_custom_color';

  Future<ThemeColorPreference> readThemeColorPreference() async {
    final preferences = await SharedPreferences.getInstance();
    final mode = preferences.getString(_modeKey);
    return switch (mode) {
      'liturgical' => ThemeColorPreference.liturgical(
        _riteForId(preferences.getString(_liturgicalRiteKey)),
      ),
      'fixed' => ThemeColorPreference.fixed(
        preferences.getString(_fixedOptionIdKey) ?? 'green',
      ),
      'custom' => ThemeColorPreference.custom(
        Color(preferences.getInt(_customColorKey) ?? 0xff208070),
      ),
      _ => const ThemeColorPreference.liturgical(LiturgicalRite.anglican),
    };
  }

  Future<void> writeThemeColorPreference(
    ThemeColorPreference preference,
  ) async {
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

class ThemeStylePreferenceService {
  const ThemeStylePreferenceService();

  static const _styleKey = 'theme_style';

  Future<ThemeStyle> readThemeStyle() async {
    final preferences = await SharedPreferences.getInstance();
    final style = preferences.getString(_styleKey);
    return ThemeStyle.values.firstWhere(
      (value) => value.name == style,
      orElse: () => ThemeStyle.traditional,
    );
  }

  Future<void> writeThemeStyle(ThemeStyle style) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_styleKey, style.name);
  }
}
