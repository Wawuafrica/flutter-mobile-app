import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/location_verification/location_verification.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/account_type_card/account_type_card.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';

class AccountType extends StatelessWidget {
  const AccountType({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 35.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomIntroBar(
              text: 'Account Type',
              desc: 'Select the user account type you want to sign up as',
            ),
            AccountTypeCard(
              navigate: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationVerification(),
                  ),
                );
              },
              cardColor: wawuColors.darkContainer,
              text: 'Professionals',
              desc:
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim.',
              textColor: Colors.white,
            ),
            SizedBox(height: 20),
            AccountTypeCard(
              navigate: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationVerification(),
                  ),
                );
              },
              cardColor: wawuColors.purpleContainer,
              text: 'Artisan',
              desc:
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim.',
              textColor: Colors.white,
            ),
            SizedBox(height: 20),
            AccountTypeCard(
              navigate: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationVerification(),
                  ),
                );
              },
              cardColor: wawuColors.white,
              text: 'Buyer',
              desc:
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim.',
              textColor: Colors.black,
              borderBlack: true,
            ),
          ],
        ),
      ),
    );
  }
}
