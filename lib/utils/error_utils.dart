import 'package:flutter/material.dart';
import '../widgets/error_support_dialog.dart';

/// Shows a persistent error dialog with an option to contact support.
Future<void> showErrorSupportDialog({
  required BuildContext context,
  required String title,
  required String message,
  bool showSupportButton = true,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ErrorSupportDialog(
      title: title,
      message: message,
      showSupportButton: showSupportButton,
    ),
  );
}
