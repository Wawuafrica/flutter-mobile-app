import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:share_plus/share_plus.dart';

class InvitePeopleScreen extends StatelessWidget {
  const InvitePeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invite People')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              height: 300,
              child: Image.asset('assets/images/onboarding_images/oi3.webp'),
            ),
            SizedBox(height: 40),
            Text('Invite your people to our app and have fun together'),
            SizedBox(height: 40),
            CustomButton(
              function: _shareContent,
              widget: Text(
                'Invite People',
                style: TextStyle(color: Colors.white),
              ),
              color: wawuColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _shareContent() {
    final String text = 'Download Wawu Now';
    final String link = 'https://example.com'; // Replace with your link

    // Combine text and link
    final String shareText = '$text\n$link';

    // Trigger the native share dialog
    Share.share(shareText);
  }
}
