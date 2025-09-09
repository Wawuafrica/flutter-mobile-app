// lib/screens/account_type/account_type.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/category_selection/category_selection.dart';
import 'package:wawu_mobile/screens/update_profile/update_profile.dart';
// import 'package:wawu_mobile/screens/category_selection/category_selection.dart'; // Removed
// import 'package:wawu_mobile/screens/location_verification/location_verification.dart'; // Removed
import 'package:wawu_mobile/utils/constants/colors.dart'; // Assuming this exists for your colors
import 'package:wawu_mobile/services/onboarding_state_service.dart';
import 'package:wawu_mobile/widgets/account_type_card/account_type_card.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';
import 'package:wawu_mobile/widgets/onboarding/onboarding_progress_indicator.dart';

class AccountType extends StatefulWidget {
  const AccountType({super.key});

  @override
  State<AccountType> createState() => _AccountTypeState();
}

class _AccountTypeState extends State<AccountType> {
  String? selectedAccountType;

  // Map string types to backend integer roles
  // THIS IS THE CORRECTED MAP AS PER YOUR SPECIFICATION:
  // 'buyer': 1, 'professional': 2, 'artisan': 3
  final Map<String, int> _roleMap = {
    'buyer': 1,
    'professional': 2,
    'artisan': 3,
  };

  // Helper to get the String representation from the backend's role string
  String? _getAccountTypeString(String? roleBackendString) {
    if (roleBackendString == null) return null;
    switch (roleBackendString.toUpperCase()) {
      case 'PROFESSIONAL':
        return 'professional';
      case 'ARTISAN':
        return 'artisan';
      case 'BUYER':
        return 'buyer';
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize selectedAccountType from currentUser if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser != null &&
          userProvider.currentUser!.role != null) {
        setState(() {
          selectedAccountType = _getAccountTypeString(
            userProvider.currentUser!.role,
          );
        });
      }
    });
  }

  // Method to handle account type selection and API call
  Future<void> _onAccountTypeSelected(String type) async {
    setState(() {
      selectedAccountType = type; // Update UI selection immediately
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final int? role =
        _roleMap[type]; // This correctly gets the new integer value

    if (role == null) {
      // This should ideally not happen if _roleMap is complete
      userProvider.setError('Invalid role selected: $type');
      return;
    }

    // Call the NEW provider method for updating account type
    await userProvider.updateAccountType(role);

    // React to the provider's state change
    if (!mounted) return; // Check if the widget is still in the tree

    if (userProvider.isSuccess) {
      await OnboardingStateService.saveRole(type);
      if (type.toUpperCase() == 'BUYER') {
        // For buyers, go straight to update profile
        await OnboardingStateService.saveStep('update_profile');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UpdateProfile()),
        );
      } else {
        // For other types, go to category selection
        await OnboardingStateService.saveStep('category_selection');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CategorySelection()),
        );
      }
      userProvider.resetState();
    } else if (userProvider.hasError) {
      // Show a SnackBar for immediate feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userProvider.errorMessage ?? 'Failed to update account type.',
          ),
        ),
      );
      // Clear onboarding state on error
      await OnboardingStateService.clear();
      userProvider.resetState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          appBar: AppBar(
            actions: [
              OnboardingProgressIndicator(
                currentStep: 'account_type',
                steps: const [
                  'account_type',
                  'category_selection',
                  'subcategory_selection',
                  'update_profile',
                  'profile_update',
                  'plan',
                  'payment',
                  'payment_processing',
                  'verify_payment',
                  'disclaimer',
                ],
                stepLabels: const {
                  'account_type': 'Account',
                  'category_selection': 'Category',
                  'subcategory_selection': 'Subcategory',
                  'update_profile': 'Intro',
                  'profile_update': 'Profile',
                  'plan': 'Plan',
                  'payment': 'Payment',
                  'payment_processing': 'Processing',
                  'verify_payment': 'Verify',
                  'disclaimer': 'Disclaimer',
                },
              ),
            ],
          ),
          body: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
              vertical: 0.0,
            ),
            child: ListView(
              children: [
                CustomIntroBar(
                  text: 'Account Type',
                  desc: 'Select the user account type you want to sign up as',
                ),

                // Show loading indicator when updating profile
                if (userProvider.isLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // Show error message if update failed and not loading
                if (userProvider.hasError && !userProvider.isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      userProvider.errorMessage ?? 'An error occurred',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Professional Card
                if (!userProvider.isLoading)
                  Column(
                    children: [
                      AccountTypeCard(
                        navigate:
                            userProvider.isLoading
                                ? () {}
                                : () => _onAccountTypeSelected('professional'),
                        cardColor: wawuColors.purpleDarkestContainer,
                        text: 'Seller',
                        desc:
                            'A highly accomplished and experienced superwoman with a proven track record, formal qualifications, and relevant certifications, operating a registered business.',
                        textColor: Colors.white,
                        selected: selectedAccountType == 'professional',
                      ),
                      SizedBox(height: 20),

                      // Artisan Card
                      // AccountTypeCard(
                      //   navigate:
                      //       userProvider.isLoading
                      //           ? () {}
                      //           : () => _onAccountTypeSelected('artisan'),
                      //   cardColor: wawuColors.purpleContainer,
                      //   text: 'Artisan',
                      //   desc:
                      //       'A super-skilled, confident, and experienced woman ready to work but waiting to get her qualifications, certifications, and business registered.',
                      //   textColor: Colors.white,
                      //   selected: selectedAccountType == 'artisan',
                      // ),
                      // SizedBox(height: 20),

                      // Buyer Card
                      AccountTypeCard(
                        navigate:
                            userProvider.isLoading
                                ? () {}
                                : () => _onAccountTypeSelected('buyer'),
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
              ],
            ),
          ),
        );
      },
    );
  }
}
