import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/subscription_iap.dart';
import 'package:wawu_mobile/providers/ad_provider.dart';
import 'package:wawu_mobile/providers/blog_provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/providers/links_provider.dart';
import 'package:wawu_mobile/providers/message_provider.dart';
import 'package:wawu_mobile/providers/notification_provider.dart';
import 'package:wawu_mobile/providers/plan_provider.dart';
import 'package:wawu_mobile/providers/product_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/contact_us_screen/contact_us_screen.dart';
import 'package:wawu_mobile/screens/faq_screen/faq_screen.dart';
import 'package:wawu_mobile/screens/invite_people_screen/invite_people_screen.dart';
import 'package:wawu_mobile/screens/main_screen/main_screen.dart';
import 'package:wawu_mobile/screens/profile/profile_screen.dart';
import 'package:wawu_mobile/screens/wawu_africa/sign_in/sign_in.dart';
import 'package:wawu_mobile/services/onboarding_state_service.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/utils/helpers/cache_manager.dart';
import 'package:wawu_mobile/widgets/custom_row_single_column/custom_row_single_column.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:wawu_mobile/widgets/full_ui_error_display.dart';
// settings_screen.dart

class SettingsScreen extends StatefulWidget {
  final ValueChanged<double>? onScroll;

  const SettingsScreen({super.key, this.onScroll});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ScrollController _internalScrollController;
  // 2. ADD STATE VARIABLES FOR VERSION INFO
  String _version = '...';
  String _buildNumber = '...';

  @override
  void initState() {
    super.initState();
    _internalScrollController = ScrollController();
    _internalScrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSubscriptionDetails();
    });
    // 4. CALL THE NEW METHOD TO GET VERSION INFO
    _initPackageInfo();
  }

  // 3. CREATE A METHOD TO GET PACKAGE INFO
  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  @override
  void dispose() {
    _internalScrollController.removeListener(_handleScroll);
    _internalScrollController.dispose();
    super.dispose();
  }

  // ... (rest of your methods like _handleScroll, _fetchSubscriptionDetails, _handleLogout, _launchLink remain unchanged)
  void _handleScroll() {
    if (widget.onScroll != null) {
      widget.onScroll!(_internalScrollController.offset);
    }
  }

  // CORRECTED fetchSubscriptionDetails
  void _fetchSubscriptionDetails() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.currentUser?.uuid;
    final userType = userProvider.currentUser?.role?.toLowerCase();
    int role = 0;

    // Only fetch subscription details for non-buyer roles
    if (userType == 'buyer' || userId == null) {
      return;
    }

    if (userType == 'artisan') {
      role = 3;
    } else if (userType == 'professional') {
      role = 2;
    } else {
      role = 1; // Default or unknown role, though we return for 'buyer'
    }

    Provider.of<PlanProvider>(
      context,
      listen: false,
    ).fetchUserSubscriptionDetails(userId, role);
  }

  Future<void> _handleLogout() async {
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
    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );

    userProvider.logout();
    await OnboardingStateService.clear();
    adProvider.reset();
    blogProvider.refresh();
    messageProvider.clearAllMessages();
    categoryProvider.clearSelectedCategory();
    categoryProvider.clearSelectedSubCategory();
    categoryProvider.clearSelectedService();
    gigProvider.clearUserData();
    notificationProvider.clearAll();
    planProvider.reset();
    productProvider.clearAll();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignIn()),
      (Route<dynamic> route) => false,
    );
  }

  // Helper function to launch URLs safely
  Future<void> _launchLink(BuildContext context, String linkName) async {
    final linksProvider = Provider.of<LinksProvider>(context, listen: false);
    // Ensure links are fetched if not already present
    if (linksProvider.links.isEmpty) {
      await linksProvider.fetchLinks();
    }
    final link = linksProvider.getLinkByName(linkName)?.link ?? '';

    if (link.isNotEmpty) {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: 'Could not open the link.',
            isError: true,
          );
        }
      }
    } else {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Link is not available at the moment.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    final user = userProvider.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor:
            wawuColors.primary, // Match the screen's background color
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    final fullName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    final displayName = fullName.isEmpty ? 'Guest' : fullName;

    return Scaffold(
      backgroundColor: wawuColors.primary,
      body: Stack(
        children: [
          // --- HEADER BACKGROUND ---
          _buildHeaderBackground(user.coverImage),

          // --- MAIN CONTENT SHEET ---
          Column(
            children: [
              // This SizedBox acts as a spacer for the header area
              const SizedBox(height: 216),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: _internalScrollController, // Attach controller
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // --- RESTORED SUBSCRIPTION CONTAINER ---
                        _buildSubscriptionSection(),

                        _buildSettingsItem(
                          icon: Icons.person_outline,
                          title: 'Account',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingsItem(
                          icon: Icons.quiz_outlined,
                          title: 'FAQ',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FAQScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingsItem(
                          icon: Icons.people_outline,
                          title: 'Invite People',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const InvitePeopleScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingsItem(
                          icon: Icons.headset_mic_outlined,
                          title: 'Contact Us',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ContactUsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingsItem(
                          icon: Icons.info_outline,
                          title: 'About Us',
                          onTap: () => _launchLink(context, 'about us'),
                        ),
                        _buildSettingsItem(
                          icon: Icons.description_outlined,
                          title: 'Terms of Use',
                          onTap: () => _launchLink(context, 'terms of use'),
                        ),

                        const SizedBox(height: 20),
                        // --- STYLED LOGOUT BUTTON (AS LIST ITEM) ---
                        _buildStyledLogoutButton(),

                        const SizedBox(height: 20),
                        _buildDeleteAccountButton(context),

                        const SizedBox(height: 20),
                        Center(
                          // 5. UPDATE THE TEXT WIDGET
                          child: Text(
                            'Version $_version ($_buildNumber)', // Use the dynamic values
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // --- HEADER FOREGROUND CONTENT ---
          _buildHeaderContent(context, displayName, user.profileImage),
        ],
      ),
    );
  }

  // ... (All other build helper methods like _buildHeaderBackground, _buildSubscriptionSection, etc., remain unchanged)
  Widget _buildHeaderBackground(String? coverImageUrl) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 236, // Height of the purple area
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base purple color (fallback)
          Container(color: wawuColors.primary),
          // Cover image if it exists
          if (coverImageUrl != null && coverImageUrl.isNotEmpty)
            CachedNetworkImage(
              cacheManager: CustomCacheManager.instance,
              imageUrl: coverImageUrl,
              memCacheHeight: 200,
              memCacheWidth: 200,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
          // Blur effect on top of the image
          if (coverImageUrl != null && coverImageUrl.isNotEmpty)
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(color: Colors.transparent),
              ),
            ),
          // Dark overlay for text contrast
          Container(color: Colors.black.withOpacity(0.25)),
        ],
      ),
    );
  }

  Widget _buildHeaderContent(
    BuildContext context,
    String displayName,
    String? profileImageUrl,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.end,
              //   children: [
              //     ElevatedButton(
              //       onPressed: () {
              //         /* TODO: Implement Help action */
              //       },
              //       style: ElevatedButton.styleFrom(
              //           backgroundColor: Colors.pinkAccent,
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(20),
              //           ),
              //           padding: const EdgeInsets.symmetric(
              //               horizontal: 20, vertical: 8)),
              //       child: const Text('Help',
              //           style: TextStyle(color: Colors.white)),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    SizedBox(
                      height: 50,
                      width: 50,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          cacheManager: CustomCacheManager.instance,
                          memCacheHeight: 200,
                          memCacheWidth: 200,
                          imageUrl: profileImageUrl ?? '',
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) =>
                                  Container(color: Colors.white24),
                          errorWidget:
                              (context, url, error) => Image.asset(
                                'assets/images/other/avatar.webp',
                                fit: BoxFit.cover,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'View your profile', // UPDATED TEXT
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection() {
    return Consumer<PlanProvider>(
      builder: (context, planProvider, child) {
        final userType =
            Provider.of<UserProvider>(
              context,
              listen: false,
            ).currentUser?.role?.toLowerCase();

        // Only show subscription section for non-buyer roles
        if (userType == 'buyer') {
          return const SizedBox.shrink();
        }

        final SubscriptionIap? subscription = planProvider.subscriptionIap;
        final bool isLoading = planProvider.isLoading;

        if (isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (subscription == null || !subscription.isActive) {
          return const SizedBox.shrink(); // Don't show anything if no active sub
        }

        final String planName =
            planProvider.selectedPlan?.name ?? 'WAWUAfrica Standard';
        final String statusText = subscription.statusDisplayText;
        final String formattedEndDate = subscription.formattedEndDate;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: wawuColors.primary,
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              CustomRowSingleColumn(
                leftText: 'Subscription Plan',
                leftTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                rightText: planName,
                rightTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              CustomRowSingleColumn(
                leftText: 'Status',
                leftTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                rightText: statusText,
                rightTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              CustomRowSingleColumn(
                leftText: 'Expires On',
                leftTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                rightText: formattedEndDate,
                rightTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStyledLogoutButton() {
    return GestureDetector(
      onTap: () async {
        await _handleLogout();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    return Center(
      child: TextButton(
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
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
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

          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => const Center(child: CircularProgressIndicator()),
          );

          final success = await userProvider.deleteUserAccount();
          Navigator.of(context).pop(); // Dismiss loading dialog

          if (success) {
            await _handleLogout();
          } else {
            if (mounted) {
              CustomSnackBar.show(
                context,
                message:
                    userProvider.errorMessage ?? 'Failed to delete account',
                isError: true,
              );
              userProvider.resetState();
            }
          }
        },
        child: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black54),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
