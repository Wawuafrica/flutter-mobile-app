import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/category_selection/category_selection.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_dropdown/custom_dropdown.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';

class LocationVerification extends StatefulWidget {
  const LocationVerification({super.key});

  @override
  State<LocationVerification> createState() => _LocationVerificationState();
}

class _LocationVerificationState extends State<LocationVerification> {
  // String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            CustomIntroBar(
              text: 'Verify Your Location',
              desc:
                  'Hello, where are you joining us from?  The next big party might be near you!',
            ),
            CustomDropdown(
              options: const ['Nigeria', 'South Africa', 'Ghana'],
              label: 'Select an option',
              // selectedValue: selectedValue,
              // onChanged: (value) {
              //   setState(() {
              //     selectedValue = value;
              //   });
              // },
              overlayColor: Colors.black.withOpacity(0.8),
              modalBackgroundColor: Colors.white,
              borderRadius: 20.0,
              padding: const EdgeInsets.all(16),
            ),
            SizedBox(height: 20),
            CustomButton(
              function: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CategorySelection()),
                );
              },
              widget: Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              color: wawuColors.buttonPrimary,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
