import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

showNotification(
  String content,
  BuildContext context, {
  Color? backgroundColor,
  TextStyle? textStyle,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        content,
        style:
            textStyle ??
            const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 12,
            ),
      ),
      backgroundColor:
          backgroundColor ??
          wawuColors.primary, // Default to Wawu primary if not provided
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
