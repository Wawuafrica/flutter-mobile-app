import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wawu_mobile/providers/plan_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/gigs_screen/gigs_screen.dart';
import 'package:wawu_mobile/screens/home_screen/home_screen.dart';
import 'package:wawu_mobile/screens/messages_screen/messages_screen.dart';
import 'package:wawu_mobile/screens/notifications/notifications.dart';
import 'package:wawu_mobile/screens/profile/profile_screen.dart';
import 'package:wawu_mobile/screens/settings_screen/settings_screen.dart';
import 'package:wawu_mobile/screens/plan/plan.dart';
import 'package:wawu_mobile/screens/showcase_screen/showcase_screen.dart';
import 'package:wawu_mobile/screens/wawu_africa/sign_in/sign_in.dart';
import 'package:wawu_mobile/screens/wawu_africa/sign_up/sign_up.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/providers/notification_provider.dart';
import 'package:wawu_mobile/utils/helpers/cache_manager.dart';
import 'package:wawu_mobile/widgets/custom_bottom_navigation_bar/custom_bottom_navigation_bar.dart';
import 'package:wawu_mobile/widgets/blocked_account_overlay.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Define the AuthModalScreen as a separate widget for the modal
class AuthModalScreen extends StatelessWidget {
  const AuthModalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
      child: SizedBox(
        height: 400,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Sign In Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: Text(
                    'Please sign in or sign up to access this feature.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(),

                // Add icon before buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: wawuColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: wawuColors.primary,
                  ),
                ),
                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      CustomButton(
                        color: wawuColors.primary,
                        function: () {
                          Navigator.of(context).pop();
                          // await OnboardingStateService.clear();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignIn(),
                            ),
                          );
                        },
                        widget: const Text(
                          'Sign In',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),
                      CustomButton(
                        color: wawuColors.white,
                        border: Border.all(color: wawuColors.primary),
                        function: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUp(),
                            ),
                          );
                        },
                        widget: const Text(
                          'Sign Up',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom route to apply background scaling
class CustomModalBottomSheetRoute<T> extends ModalBottomSheetRoute<T> {
  CustomModalBottomSheetRoute({
    required super.builder,
    required super.backgroundColor,
    required barrierColor,
    super.barrierLabel,
    super.elevation,
    super.shape,
    super.clipBehavior,
    super.isDismissible,
    super.modalBarrierColor,
    super.enableDrag,
    super.settings,
    super.transitionAnimationController,
    required super.isScrollControlled,
  });

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Scale down the background screen
    final scale =
        0.95 + (0.05 * (1 - animation.value)); // Scale from 1.0 to 0.95
    final opacity = 0.4 + (0.6 * animation.value); // Fade modal in
    return Transform.scale(
      scale: scale,
      child: Opacity(opacity: opacity, child: child),
    );
  }
}

class MainScreen extends StatefulWidget {
  final bool isAdmin;

  const MainScreen({super.key, this.isAdmin = false});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  bool _hasInitializedNotifications = false;
  bool _hasCheckedSubscription = false;
  bool _subscriptionCheckInProgress = false;
  bool _hasRequestedMicrophonePermission = false;

  double _appBarOpacity = 0.0; // New state variable for app bar opacity
  final Map<int, double> _scrollOffsets = {
    0: 0.0,
    1: 0.0,
    4: 0.0, // Updated for Settings Screen (index changed due to blog removal)
  }; // Store scroll offsets for each tab

  List<Widget> _screens = [];
  List<CustomNavItem> _customNavItems = [];

  @override
  void initState() {
    super.initState();
    _initializeScreensAndNavItems();
    _requestMicrophonePermission();
    _performInitialSubscriptionCheck();
    _fetchUserDataIfNull();

    // Initialize app bar opacity based on the initial selected tab
    _appBarOpacity =
        (_selectedIndex == 0 ||
                _selectedIndex == 1 ||
                _getSettingsScreenIndex() == _selectedIndex)
            ? 0.0
            : 1.0;
  }

  void _fetchUserDataIfNull() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser == null) {
      await userProvider.fetchCurrentUser();
    }
  }

  // Helper to get the dynamic index of the settings screen
  int _getSettingsScreenIndex() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isBuyer = userProvider.currentUser?.role?.toUpperCase() == 'BUYER';
    // If buyer: 3 screens before settings -> index 3
    // If not buyer: 4 screens before settings -> index 4
    return isBuyer ? 3 : 4;
  }

  // Callback function to update scroll offset from child screens
  void _updateScrollOffset(double offset) {
    int settingsIndex = _getSettingsScreenIndex();
    if ((_selectedIndex == 0 ||
            _selectedIndex == 1 ||
            _selectedIndex == settingsIndex) &&
        mounted) {
      const double scrollThreshold =
          150.0; // Distance after which app bar becomes fully opaque
      final newOpacity = (offset / scrollThreshold).clamp(0.0, 1.0);
      if (newOpacity != _appBarOpacity ||
          _scrollOffsets[_selectedIndex] != offset) {
        setState(() {
          _appBarOpacity = newOpacity;
          _scrollOffsets[_selectedIndex] = offset;
        });
      }
    }
  }

  /// Request microphone permission
  Future<void> _requestMicrophonePermission() async {
    if (_hasRequestedMicrophonePermission) return;

    _hasRequestedMicrophonePermission = true;

    try {
      final status = await Permission.microphone.status;

      if (status.isDenied) {
        final result = await Permission.microphone.request();

        if (result.isGranted) {
          debugPrint('[MainScreen] Microphone permission granted');
          if (mounted) {
            CustomSnackBar.show(
              context,
              message: 'Microphone permission granted for voice features',
              isError: false,
            );
          }
        } else if (result.isDenied) {
          debugPrint('[MainScreen] Microphone permission denied');
          if (mounted) {
            CustomSnackBar.show(
              context,
              message:
                  'Microphone permission denied. Voice features will be limited.',
              isError: true,
            );
          }
        } else if (result.isPermanentlyDenied) {
          debugPrint('[MainScreen] Microphone permission permanently denied');
          if (mounted) {
            // _showPermissionSettingsDialog();
          }
        }
      } else if (status.isGranted) {
        debugPrint('[MainScreen] Microphone permission already granted');
      } else if (status.isPermanentlyDenied) {
        debugPrint('[MainScreen] Microphone permission permanently denied');
        if (mounted) {
          // _showPermissionSettingsDialog();
        }
      }
    } catch (e) {
      debugPrint('[MainScreen] Error requesting microphone permission: $e');
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Unable to request microphone permission',
          isError: true,
        );
      }
    }
  }

  /// Check microphone permission status
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// --- UPDATED SUBSCRIPTION CHECK ---
  /// This method now correctly uses the PlanProvider's full logic.
  void _performInitialSubscriptionCheck() async {
    if (_hasCheckedSubscription || _subscriptionCheckInProgress) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    // Skip subscription check for BUYER role or unauthenticated users
    if (currentUser == null || currentUser.role?.toLowerCase() == 'buyer') {
      debugPrint(
        '[MainScreen] Skipping subscription check for Guest or Buyer.',
      );
      setState(() => _hasCheckedSubscription = true);
      return;
    }

    // --- FIX: RESTORED CONNECTIVITY CHECK ---
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint(
        '[MainScreen] No internet. Allowing user to continue based on cached data.',
      );
      if (mounted) {
        CustomSnackBar.show(
          context,
          message:
              'No internet connection. Subscription status may not be up to date.',
          isError: false,
        );
        // We can still try a quick load from cache, which works offline
        final planProvider = Provider.of<PlanProvider>(context, listen: false);
        await planProvider.loadCachedSubscription(currentUser.uuid);
      }
      setState(() {
        _hasCheckedSubscription = true;
        _subscriptionCheckInProgress = false;
      });
      return; // Stop further checks if offline
    }
    // --- END FIX ---

    // --- FIX: DERIVE ROLE ID FROM ROLE NAME ---
    int getRoleId(String? roleName) {
      switch (roleName?.toUpperCase()) {
        case 'BUYER':
          return 1;
        case 'PROFESSIONAL':
          return 2;
        case 'ARTISAN':
          return 3;
        default:
          return 0; // Default case for unknown roles
      }
    }

    final int roleId = getRoleId(currentUser.role);
    // --- END FIX ---

    setState(() => _subscriptionCheckInProgress = true);

    try {
      final planProvider = Provider.of<PlanProvider>(context, listen: false);

      // Enable the backend communication flags
      planProvider.setSendPurchaseToBackend(true);
      planProvider.setBackendVerificationEnabled(true);

      // Call the single, high-level method to perform the entire check
      await planProvider.fetchUserSubscriptionDetails(
        currentUser.uuid,
        roleId, // Use the correctly derived roleId
      );

      // After the check, simply consult the provider's final state
      final bool hasActiveSubscription = planProvider.hasActiveSubscription;

      if (mounted) {
        if (!hasActiveSubscription) {
          debugPrint(
            '[MainScreen] No active subscription found, redirecting to plan screen.',
          );
          // Use pushReplacement to prevent user from going back to a screen they shouldn't access
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const Plan()),
          );
        } else {
          debugPrint('[MainScreen] Active subscription confirmed.');
        }
      }
    } catch (e) {
      debugPrint(
        '[MainScreen] Error during subscription check: $e. Allowing user to continue.',
      );
      if (mounted) {
        CustomSnackBar.show(
          context,
          message:
              'Could not verify subscription status. Please check your connection.',
          isError: true,
        );
      }
    } finally {
      // Ensure the progress indicator is always hidden
      if (mounted) {
        setState(() {
          _hasCheckedSubscription = true;
          _subscriptionCheckInProgress = false;
        });
      }
    }
  }

  void _initializeScreensAndNavItems() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final notificationsProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    final currentUser = userProvider.currentUser;
    final isBuyer = currentUser?.role?.toUpperCase() == 'BUYER';

    if (!_hasInitializedNotifications && currentUser != null) {
      _hasInitializedNotifications = true;
      await notificationsProvider.fetchNotifications(currentUser.uuid);
    }

    setState(() {
      _screens = [
        HomeScreen(onScroll: _updateScrollOffset), // Pass callback
        ShowcaseScreen(onScroll: _updateScrollOffset),
        const MessagesScreen(),
        if (!isBuyer) const GigsScreen(),
        SettingsScreen(), // Pass callback
      ];

      _customNavItems = [
        CustomNavItem(iconPath: 'assets/images/svg/home.svg', label: 'Home'),
        CustomNavItem(
          iconPath: 'assets/images/svg/showcase_svg.svg',
          label: 'Showcase',
        ),
        CustomNavItem(
          iconPath: 'assets/images/svg/message.svg',
          label: 'Messages',
        ),
        if (!isBuyer)
          CustomNavItem(iconPath: 'assets/images/svg/gigs.svg', label: 'Gigs'),
        CustomNavItem(
          iconPath: 'assets/images/svg/profile_svg.svg',
          label: 'Profile',
        ),
      ];

      if (_selectedIndex >= _screens.length) {
        _selectedIndex = 0;
      }
    });
  }

  Widget _buildProfileImage(String? profileImageUrl, Color color) {
    if (profileImageUrl != null && profileImageUrl.startsWith('http')) {
      return CachedNetworkImage(
        cacheManager: CustomCacheManager.instance,
        imageUrl: profileImageUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        errorWidget:
            (context, url, error) => Image.asset(
              'assets/images/other/avatar.webp',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
        imageBuilder:
            (context, imageProvider) => Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
            ),
      );
    } else {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage(
              profileImageUrl ?? 'assets/images/other/avatar.webp',
            ),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }

  List<Widget> _getAppBarTitles(Color color) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isBuyer = userProvider.currentUser?.role?.toUpperCase() == 'BUYER';

    final List<Widget> titles = [
      // Home
      Text(
        userProvider.currentUser != null
            ? "${userProvider.currentUser?.state}, ${userProvider.currentUser?.country}."
            : "WAWUAfrica",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: color,
        ),
      ),
      // Showcase
      Text(
        userProvider.currentUser != null
            ? "${userProvider.currentUser?.state}, ${userProvider.currentUser?.country}."
            : "WAWUAfrica",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: color,
        ),
      ),
      // Messages
      const Text(
        'Messages',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      // Gigs (conditional)
      if (!isBuyer)
        const Text(
          'Gigs',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      // Settings
      Text(
        'Settings',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ];
    return titles;
  }

  void _onItemTapped(int index) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    // Allow Home and Showcase for unauthenticated users
    if (currentUser == null && ![0, 1].contains(index)) {
      _showAuthModal();
      return;
    }

    setState(() {
      _selectedIndex = index;
      // Restore the opacity and scroll position for the selected tab
      int settingsIndex = _getSettingsScreenIndex();
      if (_selectedIndex == 0 ||
          _selectedIndex == 1 ||
          _selectedIndex == settingsIndex) {
        _updateScrollOffset(_scrollOffsets[_selectedIndex] ?? 0.0);
      } else {
        _appBarOpacity = 1.0; // Fully opaque for other tabs
      }
    });
  }

  void _showAuthModal() {
    Navigator.of(context).push(
      CustomModalBottomSheetRoute(
        builder: (context) => const AuthModalScreen(),
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.4),
        isDismissible: true,
        enableDrag: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        isScrollControlled: true,
      ),
    );
  }

  List<Widget> _getAppBarActions(Color color) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    List<Widget> actions = [];

    if (currentUser != null) {
      actions.add(_buildNotificationsButton(color));
    }
    return actions;
  }

  Widget _buildInPageSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.ease,
      height: _isSearchOpen ? 65 : 0,
      child: ClipRRect(
        child: SizedBox(
          height: _isSearchOpen ? 65 : 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15.0,
              vertical: 15.0,
            ),
            child:
                _isSearchOpen
                    ? TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search...",
                        hintStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: wawuColors.primary.withAlpha(30),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: wawuColors.primary.withAlpha(60),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: wawuColors.primary),
                        ),
                      ),
                    )
                    : null,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsButton(Color iconColor) {
    return Consumer2<NotificationProvider, UserProvider>(
      builder: (context, notificationProvider, userProvider, _) {
        final int unreadCount = notificationProvider.unreadCount;
        final hasUnread = unreadCount > 0;

        return Container(
          decoration: BoxDecoration(
            color: wawuColors.purpleDarkestContainer.withOpacity(
              1.0 - _appBarOpacity,
            ),
            shape: BoxShape.circle,
          ),
          margin: const EdgeInsets.only(right: 10),
          height: 36,
          width: 36,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications,
                  size: 17,
                  color: iconColor, // Use dynamic color
                ),
                onPressed: () {
                  if (userProvider.currentUser == null) {
                    _showAuthModal();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Notifications(),
                      ),
                    );
                  }
                },
              ),
              if (hasUnread)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: wawuColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          height: 1,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int settingsIndex = _getSettingsScreenIndex();
    final isTransparentAppBar =
        _selectedIndex == 0 ||
        _selectedIndex == 1 ||
        _selectedIndex == settingsIndex;
    final defaultTextColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final appBarItemColor =
        Color.lerp(Colors.white, defaultTextColor, _appBarOpacity)!;

    final List<Widget> appBarTitles = _getAppBarTitles(appBarItemColor);
    final List<Widget> appBarActions = _getAppBarActions(appBarItemColor);

    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final isBlocked = userProvider.currentUser?.status == 'BLOCKED';

        if (isBlocked) return const BlockedAccountOverlay();

        bool isCenteredTitle = _selectedIndex == 0 || _selectedIndex == 1;

        return Stack(
          children: [
            Scaffold(
              extendBodyBehindAppBar: isTransparentAppBar,
              appBar: AppBar(
                leading:
                    _selectedIndex == 0 || _selectedIndex == 1
                        ? GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: _buildProfileImage(
                              userProvider.currentUser?.profileImage,
                              appBarItemColor, // Pass color to profile image
                            ),
                          ),
                        )
                        : null,
                title:
                    appBarTitles.length > _selectedIndex
                        ? appBarTitles[_selectedIndex]
                        : null,
                backgroundColor:
                    isTransparentAppBar
                        ? Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withOpacity(_appBarOpacity)
                        : Theme.of(context).appBarTheme.backgroundColor,
                elevation:
                    isTransparentAppBar
                        ? (_appBarOpacity *
                            (Theme.of(context).appBarTheme.elevation ??
                                0.0)) // Fade in elevation
                        : Theme.of(context).appBarTheme.elevation,
                centerTitle: isCenteredTitle,
                automaticallyImplyLeading:
                    _selectedIndex == 0 ||
                    _selectedIndex == 1 ||
                    _selectedIndex == 4,
                actions: appBarActions, // Use dynamic actions
              ),
              body: Column(
                children: [
                  _buildInPageSearchBar(),
                  const SizedBox.shrink(),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _screens,
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: CustomBottomNavigationBar(
                selectedIndex: _selectedIndex,
                onItemTapped: _onItemTapped,
                items: _customNavItems,
              ),
            ),
            // Show loading overlay when subscription check is in progress
            if (_subscriptionCheckInProgress)
              Material(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Verifying...',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
