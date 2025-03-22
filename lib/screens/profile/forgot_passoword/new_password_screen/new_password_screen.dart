import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';

class NewPasswordScreen extends StatelessWidget {
  const NewPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Password')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            // Text('Enter OTP', style: TextStyle(fontSize: 22)),
            // SizedBox(height: 20),
            CustomTextfield(
              labelText: 'Enter New Password',
              hintText: '123456789',
              labelTextStyle2: true,
            ),
            SizedBox(height: 20),
            CustomTextfield(
              labelText: 'Re-Enter New Password',
              hintText: '123456789',
              labelTextStyle2: true,
            ),
            SizedBox(height: 20),

            CustomButton(
              function: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NewPasswordScreen()),
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
