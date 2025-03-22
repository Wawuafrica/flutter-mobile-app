import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/profile/forgot_passoword/otp_screen/otp_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';

class ForgotPassword extends StatelessWidget {
  const ForgotPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Forgotten Your Password?')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              "Hey Superwoman, it's normal to forget passwords.  Just enter your email, and we'll send you a code to reset it.",
              // style: TextStyle( fontSize: 20),
            ),
            SizedBox(height: 0),
            CustomTextfield(
              hintText: 'Enter Your Email',
              labelTextStyle2: true,
            ),
            SizedBox(height: 10),
            CustomButton(
              function: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OtpScreen()),
                );
              },
              widget: Text(
                'Confirm Changes',
                style: TextStyle(color: Colors.white),
              ),
              color: wawuColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
