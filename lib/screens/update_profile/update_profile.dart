import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Added
import 'package:wawu_mobile/providers/user_provider.dart'; // Added
import 'package:wawu_mobile/screens/update_profile/profile_update/profile_update.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/onboarding/onboarding_progress_indicator.dart';

class UpdateProfile extends StatelessWidget {
  const UpdateProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Profile'),
        actions: [
          OnboardingProgressIndicator(
            currentStep: 'update_profile',
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
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            // Wrapped the user info section with Consumer
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final user = userProvider.currentUser;
                final fullName =
                    '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
                final accountType = user?.role ?? 'Loading...'; // Use user.role

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.0),
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: wawuColors.primaryBackground.withValues(
                          alpha: 0.2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(shape: BoxShape.circle),
                            child: Image.asset(
                              'assets/images/other/avatar.webp',
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            // Display dynamic full name
                            fullName.isNotEmpty ? fullName : 'User Name',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            // Display dynamic account type (role)
                            accountType,
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color.fromARGB(255, 125, 125, 125),
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            spacing: 5,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 15,
                                color: wawuColors.primary,
                              ),
                              Text(
                                'Not Verified',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: wawuColors.primary,
                                  fontWeight: FontWeight.w200,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            spacing: 5,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star,
                                size: 15,
                                color: const Color.fromARGB(255, 162, 162, 162),
                              ),
                              Icon(
                                Icons.star,
                                size: 15,
                                color: const Color.fromARGB(255, 162, 162, 162),
                              ),
                              Icon(
                                Icons.star,
                                size: 15,
                                color: const Color.fromARGB(255, 162, 162, 162),
                              ),
                              Icon(
                                Icons.star,
                                size: 15,
                                color: const Color.fromARGB(255, 162, 162, 162),
                              ),
                              Icon(
                                Icons.star,
                                size: 15,
                                color: const Color.fromARGB(255, 162, 162, 162),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Hi $fullName",
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color.fromARGB(255, 125, 125, 125),
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    Text(
                      "Your expertise on WAWUAfrica is truly remarkable, bringing both excellence and joy to the platform. Your skills and wisdom are making a real difference! To help clients connect with you more easily, remember to keep your profile updated. We’re thrilled to have you here and celebrate your success. As you glorify God, enjoy the journey, and prosper, remember His promise: Commit your work to the Lord, and your plans will be established. Keep shining for His glory! (Proverbs 16:3).",
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color.fromARGB(255, 125, 125, 125),
                        fontWeight: FontWeight.w200,
                      ),
                    ),

                    SizedBox(height: 30),
                    CustomButton(
                      function: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileUpdate(),
                          ),
                        );
                      },
                      widget: Text(
                        'Update Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      color: wawuColors.buttonPrimary,
                      textColor: Colors.white,
                    ),
                    SizedBox(height: 30),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
