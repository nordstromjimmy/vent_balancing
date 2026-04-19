import 'package:flutter/material.dart';

/// A thin wrapper around [AlertDialog] that overrides the default
/// [insetPadding] (which is 40px per side) to use the full screen width
/// with only a small margin.
///
/// Use this everywhere instead of [AlertDialog] directly.
///
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => AppDialog(
///     title: const Text('Titel'),
///     content: ...,
///     actions: [...],
///   ),
/// );
/// ```
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.scrollable = true,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;

  /// Whether the content area is scrollable. Defaults to true,
  /// which matches the behaviour needed for dialogs with many fields.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // 16px on each side instead of the default 40px → full-width feel.
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: title,
      content: content,
      actions: actions,
      scrollable: scrollable,
    );
  }
}
