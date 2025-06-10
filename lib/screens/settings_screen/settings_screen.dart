// settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/ad_provider.dart';
// import 'package:wawu_mobile/providers/application_provider.dart';
import 'package:wawu_mobile/providers/blog_provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/providers/notification_provider.dart';
import 'package:wawu_mobile/providers/plan_provider.dart'; // Import PlanProvider
import 'package:wawu_mobile/providers/product_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/about_us_screen/about_us_screen.dart';
import 'package:wawu_mobile/screens/contact_us_screen/contact_us_screen.dart';
import 'package:wawu_mobile/screens/faq_screen/faq_screen.dart';
import 'package:wawu_mobile/screens/invite_people_screen/invite_people_screen.dart';
import 'package:wawu_mobile/screens/profile/profile_screen.dart';
import 'package:wawu_mobile/screens/terms_of_use_screen/terms_of_use_screen.dart';
import 'package:wawu_mobile/screens/wawu/wawu.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_row_single_column/custom_row_single_column.dart';
import 'package:wawu_mobile/widgets/settings_button_card/settings_button_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch subscription data when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.uuid;
      final userType = userProvider.currentUser?.role?.toLowerCase();
      int role = 0; // Default role, assuming it's not artisan or professional

      if (userType == 'artisan') {
        role = 3;
      } else if (userType == 'professional') {
        role = 2;
      } else {
        role = 1; // Assuming 'user' or default role is 1
      }

      // Only call fetchUserSubscriptionDetails if userId is not null
      if (userId != null) {
        Provider.of<PlanProvider>(
          context,
          listen: false,
        ).fetchUserSubscriptionDetails(userId, role);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Container(width: double.infinity, height: 100, color: Colors.black),
            SizedBox(
              height: 50,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -50,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          final user = userProvider.currentUser;
                          final profileImageUrl = user?.profileImage;

                          return Container(
                            width: 100,
                            height: 100,
                            clipBehavior: Clip.hardEdge,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child:
                                profileImageUrl != null &&
                                        profileImageUrl.isNotEmpty
                                    ? Image.network(
                                      profileImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        // Fallback to default avatar if network image fails
                                        return Image.asset(
                                          'assets/images/other/avatar.webp',
                                          fit: BoxFit.cover,
                                        );
                                      },
                                      loadingBuilder: (
                                        context,
                                        child,
                                        loadingProgress,
                                      ) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                    )
                                    : Image.asset(
                                      'assets/images/other/avatar.webp',
                                      fit: BoxFit.cover,
                                    ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final user = userProvider.currentUser;
                final fullName =
                    '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
                final displayName = fullName.isEmpty ? 'User' : fullName;

                return Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Consumer<PlanProvider>(
              builder: (context, planProvider, child) {
                final userType =
                    Provider.of<UserProvider>(
                      context,
                    ).currentUser?.role?.toLowerCase();

                // Conditional rendering: Only show subscription if userType is 'artisan' or 'professional'
                if (userType != 'artisan' && userType != 'professional') {
                  return const SizedBox.shrink(); // Hide the subscription component
                }

                final subscriptionData = planProvider.subscription;
                final isLoading = planProvider.isLoading;
                final hasError = planProvider.hasError;

                if (isLoading) {
                  return Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey[200], // Placeholder color
                    ),
                    padding: const EdgeInsets.all(30.0),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                if (hasError || subscriptionData == null) {
                  return Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color:
                          wawuColors
                              .primary, // Or a different color for fallback
                    ),
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No active subscription',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: wawuColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            // Retry fetching only if userId is available
                            final currentUserId =
                                Provider.of<UserProvider>(
                                  context,
                                  listen: false,
                                ).currentUser?.uuid;
                            final currentUserType =
                                Provider.of<UserProvider>(
                                  context,
                                  listen: false,
                                ).currentUser?.role?.toLowerCase();
                            int currentRole = 0;
                            if (currentUserType == 'artisan') {
                              currentRole = 3;
                            } else if (currentUserType == 'professional') {
                              currentRole = 2;
                            } else {
                              currentRole = 1;
                            }

                            if (currentUserId != null) {
                              planProvider.fetchUserSubscriptionDetails(
                                currentUserId,
                                currentRole,
                              ); // Retry fetching
                            }
                          },
                          child: Text(
                            'Upgrade Plan or Retry',
                            style: TextStyle(
                              color: wawuColors.white.withOpacity(0.8),
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              decorationColor: wawuColors.white.withOpacity(
                                0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Display actual subscription data
                final planName = subscriptionData.plan.name;
                final expiresAt =
                    subscriptionData.expiresAt; // Use expiresAt from the model

                // Calculate days left (simplified example, consider using a date comparison library)
                // Assuming expiresAt is in a parseable format, e.g., 'YYYY-MM-DD'
                String daysLeftText = '';
                try {
                  final DateTime expiryDate = DateTime.parse(expiresAt);
                  final DateTime now = DateTime.now();
                  final Duration duration = expiryDate.difference(now);
                  final int days = duration.inDays;
                  if (days > 0) {
                    daysLeftText = '$days Days Left';
                  } else if (days == 0) {
                    daysLeftText = 'Expires Today';
                  } else {
                    daysLeftText = 'Expired';
                  }
                } catch (e) {
                  daysLeftText = 'N/A'; // Handle parsing errors
                  print('Error parsing expiry date: $e');
                }

                return Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: wawuColors.primary,
                  ),
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomRowSingleColumn(
                          leftText: 'Subscription Plan',
                          leftTextStyle: TextStyle(
                            color: wawuColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          rightText: planName,
                          rightTextStyle: TextStyle(
                            color: wawuColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: CustomRowSingleColumn(
                          leftText: 'Expires On', // Changed text
                          leftTextStyle: TextStyle(
                            color: wawuColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          rightText:
                              '$expiresAt ($daysLeftText)', // Display expiry date and days left
                          rightTextStyle: TextStyle(
                            color: wawuColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Expanded(
                        child: CustomRowSingleColumn(
                          leftText: 'Upgrade Plan',
                          leftTextStyle: TextStyle(
                            color: wawuColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          rightText: '',
                          rightTextStyle: TextStyle(
                            color: wawuColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // ... rest of your settings screen widgets ...
            SettingsButtonCard(
              title: 'My Profile',
              navigate: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            SettingsButtonCard(
              title: 'FAQ',
              navigate: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FAQScreen()),
                );
              },
            ),
            SettingsButtonCard(
              title: 'Invite People',
              navigate: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InvitePeopleScreen(),
                  ),
                );
              },
            ),
            SettingsButtonCard(
              title: 'Contact Us',
              navigate: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactUsScreen(),
                  ),
                );
              },
            ),
            SettingsButtonCard(
              title: 'About Us',
              navigate: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutUsScreen(),
                  ),
                );
              },
            ),
            SettingsButtonCard(
              title: 'Terms of Use',
              navigate: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsOfUseScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Center(
              child: GestureDetector(
                onTap: () async {
                  // Access providers
                  final userProvider = Provider.of<UserProvider>(
                    context,
                    listen: false,
                  );
                  final adProvider = Provider.of<AdProvider>(
                    context,
                    listen: false,
                  );
                  final blogProvider = Provider.of<BlogProvider>(
                    context,
                    listen: false,
                  );
                  final categoryProvider = Provider.of<CategoryProvider>(
                    context,
                    listen: false,
                  );
                  final gigProvider = Provider.of<GigProvider>(
                    context,
                    listen: false,
                  );
                  final notificationProvider =
                      Provider.of<NotificationProvider>(context, listen: false);
                  final planProvider = Provider.of<PlanProvider>(
                    context,
                    listen: false,
                  );
                  final productProvider = Provider.of<ProductProvider>(
                    context,
                    listen: false,
                  );

                  // Clear states of providers that have a clearAll or reset method
                  userProvider.logout();
                  adProvider.reset();
                  blogProvider.refresh();
                  categoryProvider.clearSelectedCategory();
                  categoryProvider.clearSelectedSubCategory();
                  categoryProvider.clearSelectedService();
                  gigProvider.clearAll();
                  notificationProvider.clearAll();
                  planProvider
                      .reset(); // This will now clear _subscription as well
                  productProvider.clearAll();

                  // Navigate to the login screen and clear navigation history
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const Wawu()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Color.fromARGB(255, 212, 212, 212),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
