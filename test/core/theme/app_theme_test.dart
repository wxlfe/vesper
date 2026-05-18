import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/theme/app_theme.dart';

void main() {
  test('light theme uses the twilight palette', () {
    final theme = AppTheme.light;

    expect(theme.scaffoldBackgroundColor, const Color(0xfff5f2f8));
    expect(theme.cardTheme.color, const Color(0xffffffff));
    expect(theme.colorScheme.primary, const Color(0xff6d5f99));
    expect(theme.textTheme.bodyLarge?.color, const Color(0xff211f2d));
    expect(theme.textTheme.bodyMedium?.color, const Color(0xff6f697d));
  });

  test('dark theme uses the twilight palette', () {
    final theme = AppTheme.dark;

    expect(theme.scaffoldBackgroundColor, const Color(0xff11101a));
    expect(theme.cardTheme.color, const Color(0xff1c1a28));
    expect(theme.colorScheme.primary, const Color(0xffa99ad6));
    expect(theme.textTheme.bodyLarge?.color, const Color(0xfff3f0f8));
    expect(theme.textTheme.bodyMedium?.color, const Color(0xffaaa3ba));
  });
}
