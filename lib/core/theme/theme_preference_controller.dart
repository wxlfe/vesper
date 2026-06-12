import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vesper/core/theme/theme_preference.dart';
import 'package:vesper/core/theme/theme_preference_service.dart';

final themeColorPreferenceServiceProvider =
    Provider<ThemeColorPreferenceService>(
      (ref) => const ThemeColorPreferenceService(),
    );

final themeStylePreferenceServiceProvider =
    Provider<ThemeStylePreferenceService>(
      (ref) => const ThemeStylePreferenceService(),
    );

final themeColorPreferenceProvider =
    AsyncNotifierProvider<ThemeColorPreferenceController, ThemeColorPreference>(
      ThemeColorPreferenceController.new,
    );

final themeStylePreferenceProvider =
    AsyncNotifierProvider<ThemeStylePreferenceController, ThemeStyle>(
      ThemeStylePreferenceController.new,
    );

class ThemeColorPreferenceController
    extends AsyncNotifier<ThemeColorPreference> {
  @override
  Future<ThemeColorPreference> build() {
    return ref
        .watch(themeColorPreferenceServiceProvider)
        .readThemeColorPreference();
  }

  Future<void> setLiturgicalRite(LiturgicalRite rite) async {
    await _setPreference(ThemeColorPreference.liturgical(rite));
  }

  Future<void> setFixed(String optionId) async {
    await _setPreference(ThemeColorPreference.fixed(optionId));
  }

  Future<void> setCustom(Color color) async {
    await _setPreference(ThemeColorPreference.custom(color));
  }

  Future<void> _setPreference(ThemeColorPreference preference) async {
    state = AsyncData(preference);
    await ref
        .read(themeColorPreferenceServiceProvider)
        .writeThemeColorPreference(preference);
  }
}

class ThemeStylePreferenceController extends AsyncNotifier<ThemeStyle> {
  @override
  Future<ThemeStyle> build() {
    return ref.watch(themeStylePreferenceServiceProvider).readThemeStyle();
  }

  Future<void> setThemeStyle(ThemeStyle style) async {
    state = AsyncData(style);
    await ref.read(themeStylePreferenceServiceProvider).writeThemeStyle(style);
  }
}
