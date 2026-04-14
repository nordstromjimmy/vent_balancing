import 'package:flutter/material.dart';

/// A simple labeled section divider used to group related content.
///
/// Usage:
/// ```dart
/// Section(title: 'Flöden'),
/// // ...content...
/// ```
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 6),
  });

  final String title;

  /// Optional widget placed at the end of the header row (e.g. an action button).
  final Widget? trailing;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.outline,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w700,
      ),
    );

    return Padding(
      padding: padding,
      child: trailing == null
          ? label
          : Row(
              children: [
                Expanded(child: label),
                trailing!,
              ],
            ),
    );
  }
}
