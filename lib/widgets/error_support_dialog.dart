import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A reusable error dialog that offers a contact support action.
class ErrorSupportDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool showSupportButton;

  const ErrorSupportDialog({
    Key? key,
    required this.title,
    required this.message,
    this.showSupportButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        if (showSupportButton)
          TextButton.icon(
            icon: const Icon(Icons.mail_outline),
            label: const Text('Contact Support'),
            onPressed: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'support@wawuafrica.com',
                query: 'subject=App Support Request',
              );
              if (await canLaunchUrl(emailLaunchUri)) {
                await launchUrl(emailLaunchUri);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open mail app.')),
                );
              }
            },
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
