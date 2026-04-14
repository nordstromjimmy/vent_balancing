import 'package:flutter/material.dart';

/// The app's [ThemeData]. Pass this to [MaterialApp.theme].
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.blueGrey,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.action,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      foregroundColor: Colors.white,
      backgroundColor: AppColors.action,
    ),
  );
}

/// Shared color constants so "the dark button color" is defined once.
abstract final class AppColors {
  /// Primary action color — used for FABs, filled buttons, and confirm dialogs.
  static const Color action = Colors.black54;
}

/// A [ButtonStyle] for filled buttons that match the app's action color.
/// Use this directly when [FilledButtonThemeData] isn't picked up automatically,
/// e.g. inside dialogs.
const ButtonStyle kFilledActionStyle = ButtonStyle(
  foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
  backgroundColor: WidgetStatePropertyAll<Color>(AppColors.action),
);

/// A [ButtonStyle] for cancel/secondary text buttons.
const ButtonStyle kTextCancelStyle = ButtonStyle(
  foregroundColor: WidgetStatePropertyAll<Color>(AppColors.action),
);
