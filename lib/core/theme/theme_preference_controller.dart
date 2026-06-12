import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vesper/core/theme/theme_preference.dart';
import 'package:vesper/core/theme/theme_preference_service.dart';

final themePreferenceServiceProvider = Provider<ThemePreferenceService>(
  (ref) => const ThemePreferenceService(),
);

final themePreferenceProvider =
    AsyncNotifierProvider<ThemePreferenceController, ThemePreference>(
      ThemePreferenceController.new,
    );

class ThemePreferenceController extends AsyncNotifier<ThemePreference> {
  @override
  Future<ThemePreference> build() {
    return ref.watch(themePreferenceServiceProvider).readThemePreference();
  }

  Future<void> setLiturgicalRite(LiturgicalRite rite) async {
    await _setPreference(ThemePreference.liturgical(rite));
  }

  Future<void> setFixed(String optionId) async {
    await _setPreference(ThemePreference.fixed(optionId));
  }

  Future<void> setCustom(Color color) async {
    await _setPreference(ThemePreference.custom(color));
  }

  Future<void> _setPreference(ThemePreference preference) async {
    state = AsyncData(preference);
    await ref
        .read(themePreferenceServiceProvider)
        .writeThemePreference(preference);
  }
}
