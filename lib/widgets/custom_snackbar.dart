import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

/// A reusable widget to display custom SnackBar messages.
///
/// This SnackBar provides a consistent look and feel for error, success,
/// or informational messages across the application. It supports an optional
/// action button for retry or other user interactions.
class CustomSnackBar {
  /// Shows a SnackBar with a message and optional action.
  ///
  /// [context]: The BuildContext to show the SnackBar.
  /// [message]: The message to display in the SnackBar.
  /// [isError]: If true, the background color will be red; otherwise, it will be green.
  /// [actionLabel]: Optional label for an action button (e.g., 'RETRY').
  /// [onActionPressed]: Callback function for the action button.
  static void show(
    BuildContext context, {
    required String message,
    bool isError = true,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    // Ensure the context is still valid before showing the SnackBar
    if (!context.mounted) {
      return;
    }

    // Clear any existing SnackBars to prevent stacking
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade700 : wawuColors.primary,
        behavior:
            SnackBarBehavior.floating, // Makes it float above bottom navigation
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(16.0), // Padding from edges
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        duration: const Duration(seconds: 4),
        action:
            actionLabel != null && onActionPressed != null
                ? SnackBarAction(
                  label: actionLabel,
                  onPressed: onActionPressed,
                  textColor: Colors.white,
                )
                : null,
      ),
    );
  }
}
