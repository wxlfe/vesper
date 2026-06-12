import 'package:flutter/material.dart';

enum ThemeColorMode { liturgical, fixed, custom }

enum ThemeStyle { traditional, contemporary }

enum LiturgicalRite { roman, byzantine, russian, coptic, lutheran, anglican }

class ThemeColorPreference {
  const ThemeColorPreference.liturgical([
    this.liturgicalRite = LiturgicalRite.anglican,
  ]) : mode = ThemeColorMode.liturgical,
       fixedOptionId = null,
       customColor = null;

  const ThemeColorPreference.fixed(String optionId)
    : mode = ThemeColorMode.fixed,
      liturgicalRite = null,
      fixedOptionId = optionId,
      customColor = null;

  const ThemeColorPreference.custom(Color color)
    : mode = ThemeColorMode.custom,
      liturgicalRite = null,
      fixedOptionId = null,
      customColor = color;

  final ThemeColorMode mode;
  final LiturgicalRite? liturgicalRite;
  final String? fixedOptionId;
  final Color? customColor;

  @override
  bool operator ==(Object other) {
    return other is ThemeColorPreference &&
        other.mode == mode &&
        other.liturgicalRite == liturgicalRite &&
        other.fixedOptionId == fixedOptionId &&
        other.customColor == customColor;
  }

  @override
  int get hashCode =>
      Object.hash(mode, liturgicalRite, fixedOptionId, customColor);
}

class LiturgicalThemeOption {
  const LiturgicalThemeOption({
    required this.id,
    required this.label,
    required this.rite,
  });

  final String id;
  final String label;
  final LiturgicalRite rite;
}

class ThemeColorOption {
  const ThemeColorOption({
    required this.id,
    required this.label,
    required this.lightColor,
    required this.darkColor,
  });

  final String id;
  final String label;
  final Color lightColor;
  final Color darkColor;
}
