import 'package:flutter/material.dart';

Future<String?> showTextInputDialog({
  required BuildContext context,
  required String title,
  required String labelText,
  String? initialValue,
  String? hintText,
  String confirmText = 'Spara',
}) async {
  return showDialog<String>(
    context: context,
    builder: (context) {
      final c = TextEditingController(text: initialValue ?? '');
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          autofocus: false,
          decoration: InputDecoration(labelText: labelText, hintText: hintText),
          onSubmitted: (_) => Navigator.pop(context, c.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ångra'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
}

Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Radera',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ångra'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
