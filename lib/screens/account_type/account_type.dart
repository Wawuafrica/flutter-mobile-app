import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/category_selection/category_selection.dart';
import 'package:wawu_mobile/screens/location_verification/location_verification.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/account_type_card/account_type_card.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';

class AccountType extends StatefulWidget {
  const AccountType({super.key});

  @override
  State<AccountType> createState() => _AccountTypeState();
}

class _AccountTypeState extends State<AccountType> {
  String? selectedAccountType;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
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
            
            // Show loading indicator when updating profile
            if (userProvider.isLoading)
              Center(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: CircularProgressIndicator(),
              )),
              
            // Show error message if update failed
            if (userProvider.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  userProvider.errorMessage ?? 'An error occurred',
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            AccountTypeCard(
              navigate: () async {
                setState(() {
                  selectedAccountType = 'professional';
                });
                
                // Update user profile with account type
                await userProvider.updateCurrentUserProfile({
                  'account_type': 'professional',
                });
                
                if (userProvider.isSuccess) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategorySelection(),
                    ),
                  );
                }
              },
              cardColor: wawuColors.purpleDarkestContainer,
              text: 'Professionals',
              desc:
                  'A highly accomplished and experienced superwoman with a proven track record, formal qualifications, and relevant certifications, operating a registered business.',
              textColor: Colors.white,
              selected: selectedAccountType == 'professional',
            ),
            SizedBox(height: 20),
            AccountTypeCard(
              navigate: () async {
                setState(() {
                  selectedAccountType = 'artisan';
                });
                
                // Update user profile with account type
                await userProvider.updateCurrentUserProfile({
                  'account_type': 'artisan',
                });
                
                if (userProvider.isSuccess) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategorySelection(),
                    ),
                  );
                }
              },
              cardColor: wawuColors.purpleContainer,
              text: 'Artisan',
              desc:
                  'A super-skilled, confident, and experienced woman ready to work but waiting to get her qualifications, certifications, and business registered.',
              textColor: Colors.white,
              selected: selectedAccountType == 'artisan',
            ),
            SizedBox(height: 20),
            AccountTypeCard(
              navigate: () async {
                setState(() {
                  selectedAccountType = 'buyer';
                });
                
                // Update user profile with account type
                await userProvider.updateCurrentUserProfile({
                  'account_type': 'buyer',
                });
                
                if (userProvider.isSuccess) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategorySelection(),
                    ),
                  );
                }
              },
              cardColor: wawuColors.white,
              text: 'Buyer',
              desc:
                  'High-achieving professionals, entrepreneurs, industry leaders, change agents, creative geniuses, and individuals ready to pay a Superwoman to get the Wow Experience.',
              textColor: Colors.black,
              borderBlack: true,
              selected: selectedAccountType == 'buyer',
            ),
            SizedBox(height: 20.0),
          ],
        ),
      ),
        );
      },
    );
  }
}
