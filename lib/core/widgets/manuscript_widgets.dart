import 'package:flutter/material.dart';

class ManuscriptCard extends StatelessWidget {
  const ManuscriptCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.accentColor,
    this.innerBorder = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;
  final bool innerBorder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final outline = colorScheme.outline;
    final accent = accentColor ?? colorScheme.secondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outline),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: innerBorder
                ? Border.all(color: accent.withValues(alpha: 0.45))
                : null,
          ),
          child: Padding(padding: padding, child: child),
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
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelLarge?.copyWith(
        color: color ?? theme.colorScheme.primary,
        letterSpacing: 1.1,
      ),
    );
  }
}

class IlluminatedDivider extends StatelessWidget {
  const IlluminatedDivider({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
