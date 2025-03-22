import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/profile/forgot_passoword/forgot_password.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            CustomTextfield(
              hintText: '********',
              labelText: 'Enter Current Password',
              labelTextStyle2: true,
            ),
            SizedBox(height: 10),
            CustomTextfield(
              hintText: '********',
              labelText: 'Enter New Password',
              labelTextStyle2: true,
            ),
            SizedBox(height: 10),
            CustomTextfield(
              hintText: '********',
              labelText: 'Re-Enter New Password',
              labelTextStyle2: true,
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ForgotPassword()),
                );
              },
              child: Text(
                'Forgot Password',
                style: TextStyle(color: wawuColors.buttonSecondary),
              ),
            ),
            SizedBox(height: 20),
            CustomButton(
              function: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => ChangePasswordScreen(),
                //   ),
                // );
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
