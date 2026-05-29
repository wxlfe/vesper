import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/theme/app_theme.dart';

void main() {
  test('light theme uses the green palette', () {
    final theme = AppTheme.light;

    expect(theme.scaffoldBackgroundColor, const Color(0xfff4f6f0));
    expect(theme.cardTheme.color, const Color(0xffffffff));
    expect(theme.colorScheme.primary, const Color(0xff5f725b));
    expect(theme.textTheme.bodyLarge?.color, const Color(0xff242b24));
    expect(theme.textTheme.bodyMedium?.color, const Color(0xff6a7267));
  });

  test('dark theme uses the green palette', () {
    final theme = AppTheme.dark;

    expect(theme.scaffoldBackgroundColor, const Color(0xff111610));
    expect(theme.cardTheme.color, const Color(0xff1b211a));
    expect(theme.colorScheme.primary, const Color(0xffa3b39d));
    expect(theme.textTheme.bodyLarge?.color, const Color(0xffedf2ea));
    expect(theme.textTheme.bodyMedium?.color, const Color(0xffa9b1a5));
  });
}
