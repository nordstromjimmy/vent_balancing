import 'package:flutter/material.dart';

import '../widgets/app_dialog.dart';

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
    // StatefulBuilder so we can show inline validation without a full widget.
    builder: (context) {
      final c = TextEditingController(text: initialValue ?? '');
      bool showError = false;

      void trySubmit(StateSetter setDialogState) {
        if (c.text.trim().isEmpty) {
          setDialogState(() => showError = true);
          return;
        }
        Navigator.pop(context, c.text.trim());
      }

      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AppDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: c,
                  autofocus: false,
                  decoration: InputDecoration(
                    labelText: labelText,
                    hintText: hintText,
                    // Red border when empty submit attempted
                    focusedBorder: showError
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFBF2020),
                              width: 2,
                            ),
                          )
                        : null,
                    enabledBorder: showError
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFBF2020),
                            ),
                          )
                        : null,
                  ),
                  // Clear the error as soon as the user starts typing
                  onChanged: (_) {
                    if (showError) setDialogState(() => showError = false);
                  },
                  onSubmitted: (_) => trySubmit(setDialogState),
                ),
                if (showError) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Ange ett namn',
                    style: TextStyle(
                      color: Color(0xFFBF2020),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Ångra'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => trySubmit(setDialogState),
                    child: Text(confirmText),
                  ),
                ],
              ),
            ],
          );
        },
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
      return AppDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Ångra'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmText),
              ),
            ],
          ),
        ],
      );
    },
  );
  return result ?? false;
}
