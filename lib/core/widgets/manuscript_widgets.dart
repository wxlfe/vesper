import 'package:flutter/material.dart';
import 'package:vesper/core/theme/app_theme.dart';
import 'package:vesper/core/theme/theme_preference.dart';

class ManuscriptCard extends StatelessWidget {
  const ManuscriptCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.innerBorder = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool innerBorder;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<VesperThemeTokens>();
    if (tokens?.style == ThemeStyle.contemporary) {
      return Card(
        elevation: 1,
        child: Padding(padding: padding, child: child),
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = colorScheme.secondary.withValues(alpha: 0.45);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: innerBorder ? Border.all(color: borderColor) : null,
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class RubricText extends StatelessWidget {
  const RubricText(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = color ?? colorScheme.primary;
    final tokens = theme.extension<VesperThemeTokens>();
    if (tokens?.style == ThemeStyle.contemporary) {
      return ReadableAccentText(
        text,
        color: accent,
        style: theme.textTheme.labelLarge,
        backgroundKey: const Key('rubric-text-readable-background'),
      );
    }
    return ReadableAccentText(
      text.toUpperCase(),
      color: accent,
      style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.1),
      backgroundKey: const Key('rubric-text-readable-background'),
    );
  }
}

class ReadableAccentText extends StatelessWidget {
  const ReadableAccentText(
    this.text, {
    super.key,
    required this.color,
    this.style,
    this.backgroundKey,
  });

  final String text;
  final Color color;
  final TextStyle? style;
  final Key? backgroundKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = Text(text, style: style?.copyWith(color: color));
    if (_contrastRatio(color, colorScheme.surface) >= 4.5) return label;

    return DecoratedBox(
      key: backgroundKey,
      decoration: BoxDecoration(
        color: colorScheme.onSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: label,
      ),
    );
  }

  double _contrastRatio(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();
    final lighter = foregroundLuminance > backgroundLuminance
        ? foregroundLuminance
        : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance
        ? backgroundLuminance
        : foregroundLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }
}

class IlluminatedDivider extends StatelessWidget {
  const IlluminatedDivider({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<VesperThemeTokens>();
    if (tokens?.style == ThemeStyle.contemporary) {
      return SizedBox(
        height: compact ? 12 : 20,
        child: Divider(color: colorScheme.outlineVariant),
      );
    }
    final height = compact ? 16.0 : 24.0;
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(child: Divider(color: colorScheme.outline)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const SizedBox(width: 7, height: 7),
            ),
          ),
          Expanded(child: Divider(color: colorScheme.outline)),
        ],
      ),
    );
  }
}
