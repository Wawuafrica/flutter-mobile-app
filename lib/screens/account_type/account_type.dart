import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/location_verification/location_verification.dart';
import 'package:wawu_mobile/screens/wawu_africa/sign_up/provider/user_provider.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/account_type_card/account_type_card.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';
import 'package:provider/provider.dart';

class AccountType extends StatelessWidget {
  final Map<String, dynamic> userData;

  const AccountType({super.key, required this.userData});

  void _handleAccountTypeSelection(BuildContext context, String accountType) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userData['accountType'] = accountType; // Add account type to user data

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    userProvider
        .handleSignUp(userData, context)
        .then((_) {
          Navigator.pop(context); // Close the loading dialog
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LocationVerification()),
          );
        })
        .catchError((error) {
          Navigator.pop(context); // Close the loading dialog
          // Handle error, show notification or dialog
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 0.0),
        child: ListView(
          children: [
            SizedBox(height: 10.0),
            CustomIntroBar(
              text: 'Account Type',
              desc: 'Select the user account type you want to sign up as',
            ),
            AccountTypeCard(
              navigate:
                  () => _handleAccountTypeSelection(context, 'Professionals'),
              cardColor: wawuColors.purpleDarkestContainer,
              text: 'Professionals',
              desc:
                  'A highly accomplished and experienced superwoman with a proven track record, formal qualifications, and relevant certifications, operating a registered business.',
              textColor: Colors.white,
            ),
            SizedBox(height: 20),
            AccountTypeCard(
              navigate: () => _handleAccountTypeSelection(context, 'Artisan'),
              cardColor: wawuColors.purpleContainer,
              text: 'Artisan',
              desc:
                  'A super-skilled, confident, and experienced woman ready to work but waiting to get her qualifications, certifications, and business registered.',
              textColor: Colors.white,
            ),
            SizedBox(height: 20),
            AccountTypeCard(
              navigate: () => _handleAccountTypeSelection(context, 'Buyer'),
              cardColor: wawuColors.white,
              text: 'Buyer',
              desc:
                  'High-achieving professionals, entrepreneurs, industry leaders, change agents, creative geniuses, and individuals ready to pay a Superwoman to get the Wow Experience.',
              textColor: Colors.black,
              borderBlack: true,
            ),
            SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}
