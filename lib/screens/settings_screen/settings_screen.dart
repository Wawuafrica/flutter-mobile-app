// settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add this import
import 'package:wawu_mobile/providers/ad_provider.dart';
import 'package:wawu_mobile/providers/blog_provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/providers/notification_provider.dart';
import 'package:wawu_mobile/providers/plan_provider.dart';
import 'package:wawu_mobile/providers/product_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/contact_us_screen/contact_us_screen.dart';
import 'package:wawu_mobile/screens/faq_screen/faq_screen.dart';
import 'package:wawu_mobile/screens/invite_people_screen/invite_people_screen.dart';
// import 'package:wawu_mobile/screens/notifications_test.dart';
import 'package:wawu_mobile/screens/profile/profile_screen.dart';
import 'package:wawu_mobile/providers/links_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wawu_mobile/screens/wawu/wawu.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_row_single_column/custom_row_single_column.dart';
import 'package:wawu_mobile/widgets/settings_button_card/settings_button_card.dart';
import 'package:wawu_mobile/services/onboarding_state_service.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart'; // Import CustomSnackBar
import 'package:wawu_mobile/widgets/full_ui_error_display.dart'; // Import FullErrorDisplay

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Flag to prevent showing multiple snackbars for the same error
  bool _hasShownError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSubscriptionDetails();
    });
  }

  void _fetchSubscriptionDetails() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.currentUser?.uuid;
    final userType = userProvider.currentUser?.role?.toLowerCase();
    int role = 0;

    if (userType == 'artisan') {
      role = 3;
    } else if (userType == 'professional') {
      role = 2;
    } else {
      role = 1;
    }

    if (userId != null) {
      Provider.of<PlanProvider>(
        context,
        listen: false,
      ).fetchUserSubscriptionDetails(userId, role);
    }
  }

  // Build cached cover image widget
  Widget _buildCoverImage(String? coverImageUrl) {
    if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverImageUrl,
        width: double.infinity,
        height: 100,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              width: double.infinity,
              height: 100,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
        errorWidget:
            (context, url, error) => Container(
              width: double.infinity,
              height: 100,
              color: Colors.black,
            ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: 100,
        color: Colors.black,
      );
    }
  }

  // Build cached profile image widget
  Widget _buildProfileImage(String? profileImageUrl) {
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: profileImageUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
        errorWidget:
            (context, url, error) => Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/other/avatar.webp'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
        imageBuilder:
            (context, imageProvider) => Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
            ),
      );
    } else {
      return Container(
        width: 100,
        height: 100,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage('assets/images/other/avatar.webp'),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }

  // Function to show the support dialog (can be reused)
  void _showErrorSupportDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Contact Support',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: wawuColors.primary,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: wawuColors.buttonSecondary),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogoutAsync(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    final blogProvider = Provider.of<BlogProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final gigProvider = Provider.of<GigProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    userProvider.logout();
    await OnboardingStateService.clear();
    adProvider.reset();
    blogProvider.refresh();
    categoryProvider.clearSelectedCategory();
    categoryProvider.clearSelectedSubCategory();
    categoryProvider.clearSelectedService();
    gigProvider.clearAll();
    notificationProvider.clearAll();
    planProvider.reset();
    productProvider.clearAll();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Wawu()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            // Cover Image Section
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final user = userProvider.currentUser;
                final coverImageUrl = user?.coverImage;
                return _buildCoverImage(coverImageUrl);
              },
            ),
            // Profile Image Section
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
                          return _buildProfileImage(profileImageUrl);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // User Name Section
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                // Listen for errors from UserProvider and display SnackBar
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (userProvider.hasError &&
                      userProvider.errorMessage != null &&
                      !_hasShownError) {
                    CustomSnackBar.show(
                      context,
                      message: userProvider.errorMessage!,
                      isError: true,
                    );
                    _hasShownError = true;
                    userProvider.resetState(); // Clear error state
                  } else if (!userProvider.hasError && _hasShownError) {
                    _hasShownError = false;
                  }
                });

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
            // Subscription Section
            Consumer<PlanProvider>(
              builder: (context, planProvider, child) {
                // Listen for errors from PlanProvider and display SnackBar
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (planProvider.hasError &&
                      planProvider.errorMessage != null &&
                      !_hasShownError) {
                    CustomSnackBar.show(
                      context,
                      message: planProvider.errorMessage!,
                      isError: true,
                      actionLabel: 'RETRY',
                      onActionPressed: () {
                        _fetchSubscriptionDetails();
                      },
                    );
                    _hasShownError = true;
                    planProvider.clearError(); // Clear error state
                  } else if (!planProvider.hasError && _hasShownError) {
                    _hasShownError = false;
                  }
                });

                final userType =
                    Provider.of<UserProvider>(
                      context,
                    ).currentUser?.role?.toLowerCase();

                if (userType != 'artisan' && userType != 'professional') {
                  return const SizedBox.shrink();
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
                      color: Colors.grey[200],
                    ),
                    padding: const EdgeInsets.all(30.0),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                // Display full error screen for critical loading failures for subscription
                if (hasError && subscriptionData == null && !isLoading) {
                  return FullErrorDisplay(
                    errorMessage:
                        planProvider.errorMessage ??
                        'Failed to load subscription details. Please try again.',
                    onRetry: () {
                      _fetchSubscriptionDetails();
                    },
                    onContactSupport: () {
                      _showErrorSupportDialog(
                        context,
                        'If this problem persists, please contact our support team. We are here to help!',
                      );
                    },
                  );
                }

                if (subscriptionData == null) {
                  return Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: wawuColors.primary,
                    ),
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
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
                            _fetchSubscriptionDetails(); // Retry fetching subscription
                          },
                          child: Text(
                            'Upgrade Plan or Retry',
                            style: TextStyle(
                              color: wawuColors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              decorationColor: wawuColors.white.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final planName = subscriptionData.plan?.name;
                final expiresAt = subscriptionData.expiresAt;
                String daysLeftText = '';
                if (expiresAt == null || expiresAt.isEmpty) {
                  daysLeftText = 'N/A';
                } else {
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
                    daysLeftText = 'N/A';
                  }
                }

                return Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: wawuColors.primary,
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomRowSingleColumn(
                          leftText: 'Subscription Plan',
                          leftTextStyle: const TextStyle(
                            color: wawuColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          rightText: planName ?? 'N/A',
                          rightTextStyle: const TextStyle(
                            color: wawuColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: CustomRowSingleColumn(
                          leftText: 'Expires On',
                          leftTextStyle: const TextStyle(
                            color: wawuColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          rightText: '$expiresAt ($daysLeftText)',
                          rightTextStyle: const TextStyle(
                            color: wawuColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Settings Options
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
            Consumer<LinksProvider>(
              builder: (context, linksProvider, _) {
                // Listen for errors from LinksProvider and display SnackBar
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (linksProvider.hasError &&
                      linksProvider.errorMessage != null &&
                      !_hasShownError) {
                    CustomSnackBar.show(
                      context,
                      message: linksProvider.errorMessage!,
                      isError: true,
                      actionLabel: 'RETRY',
                      onActionPressed: () {
                        linksProvider.fetchLinks();
                      },
                    );
                    _hasShownError = true;
                    linksProvider.clearError(); // Clear error state
                  } else if (!linksProvider.hasError && _hasShownError) {
                    _hasShownError = false;
                  }
                });

                final termsLink =
                    linksProvider.getLinkByName('hand book')?.link ?? '';
                return SettingsButtonCard(
                  title: 'About Us',
                  navigate: () async {
                    if (termsLink.isNotEmpty) {
                      final uri = Uri.parse(termsLink);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        CustomSnackBar.show(
                          context,
                          message: 'Could not open About Us link.',
                          isError: true,
                        );
                      }
                    } else {
                      CustomSnackBar.show(
                        context,
                        message: 'About Us link is not available.',
                        isError: true,
                      );
                    }
                  },
                );
              },
            ),
            Consumer<LinksProvider>(
              builder: (context, linksProvider, _) {
                final termsLink =
                    linksProvider.getLinkByName('terms of use')?.link ?? '';
                return SettingsButtonCard(
                  title: 'Terms of Use',
                  navigate: () async {
                    if (termsLink.isNotEmpty) {
                      final uri = Uri.parse(termsLink);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        CustomSnackBar.show(
                          context,
                          message: 'Could not open Terms of Use link.',
                          isError: true,
                        );
                      }
                    } else {
                      CustomSnackBar.show(
                        context,
                        message: 'Terms of Use link is not available.',
                        isError: true,
                      );
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 10),
             FloatingActionButton(
             onPressed: () {
            Navigator.push(
             context,
             MaterialPageRoute(
             builder: (context) => const NotificationTestPage(),
               ),
               );
            },
              child: const Icon(Icons.bug_report),
             ),
            const SizedBox(height: 40),
            // Action Buttons
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(180, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    label: const Text('Delete Account'),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Delete Account'),
                              content: const Text(
                                'Are you sure you want to delete your account? This action is irreversible.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );
                      if (confirmed != true) return;
                      final userProvider = Provider.of<UserProvider>(
                        context,
                        listen: false,
                      );
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder:
                            (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                      );
                      final success = await userProvider.deleteUserAccount();
                      Navigator.of(context).pop(); // Dismiss loading dialog
                      if (success) {
                        await _handleLogoutAsync(context);
                      } else {
                        CustomSnackBar.show(
                          context,
                          message:
                              userProvider.errorMessage ??
                              'Failed to delete account',
                          isError: true,
                        );
                        userProvider.resetState(); // Clear error state
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () async {
                      await _handleLogoutAsync(context);
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
          ],
        ),
      ),
    );
  }
}
