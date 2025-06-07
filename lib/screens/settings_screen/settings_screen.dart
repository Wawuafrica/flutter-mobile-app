import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/ad_provider.dart';
import 'package:wawu_mobile/providers/application_provider.dart';
import 'package:wawu_mobile/providers/blog_provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/providers/notification_provider.dart';
import 'package:wawu_mobile/providers/plan_provider.dart';
import 'package:wawu_mobile/providers/product_provider.dart';
import 'package:wawu_mobile/providers/review_provider.dart';
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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            Container(
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
                      rightText: 'Wawu Standard',
                      rightTextStyle: TextStyle(
                        color: wawuColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomRowSingleColumn(
                      leftText: 'One Month Plan',
                      leftTextStyle: TextStyle(
                        color: wawuColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      rightText: '28 Days Left',
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
            ),
            const SizedBox(height: 20),
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
            // SettingsButtonCard(title: 'Checkout Details', navigate: () {}),
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
                  final applicationProvider = Provider.of<ApplicationProvider>(
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
                  // final messageProvider = Provider.of<MessageProvider>(context, listen: false);
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
                  final reviewProvider = Provider.of<ReviewProvider>(
                    context,
                    listen: false,
                  );

                  // Clear states of providers that have a clearAll or reset method
                  userProvider
                      .logout(); // UserProvider has a specific logout which also clears state
                  adProvider.reset();
                  applicationProvider.clearAll();
                  blogProvider.refresh();
                  // CategoryProvider does not have a clearAll or reset, clear selected states individually
                  categoryProvider.clearSelectedCategory();
                  categoryProvider.clearSelectedSubCategory();
                  categoryProvider.clearSelectedService();
                  gigProvider.clearAll();
                  // MessageProvider does not have a clearAll or reset
                  // NotificationProvider has clearAll
                  notificationProvider.clearAll();
                  planProvider.reset();
                  productProvider.clearAll();
                  reviewProvider.clearAll();

                  // Navigate to the login screen and clear navigation history
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Wawu(),
                    ), // Replace Wawu() with your login screen widget
                    (Route<dynamic> route) =>
                        false, // This predicate removes all routes from the stack
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
