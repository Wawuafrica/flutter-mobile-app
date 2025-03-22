import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/profile/forgot_passoword/new_password_screen/new_password_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verification')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text('Enter OTP', style: TextStyle(fontSize: 22)),
            CustomTextfield(hintText: '123456', labelTextStyle2: true),
            SizedBox(height: 20),
            CustomButton(
              function: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NewPasswordScreen()),
                );
              },
              widget: Text('Verify OTP', style: TextStyle(color: Colors.white)),
              color: wawuColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
