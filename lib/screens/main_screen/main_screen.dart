import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wawu_mobile/providers/plan_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/blog_screen/blog_screen.dart';
import 'package:wawu_mobile/screens/gigs_screen/gigs_screen.dart';
import 'package:wawu_mobile/screens/home_screen/home_screen.dart';
import 'package:wawu_mobile/screens/messages_screen/messages_screen.dart';
import 'package:wawu_mobile/screens/notifications/notifications.dart';
import 'package:wawu_mobile/screens/settings_screen/settings_screen.dart';
import 'package:wawu_mobile/screens/plan/plan.dart';
import 'package:wawu_mobile/screens/wawu_africa/sign_in/sign_in.dart';
import 'package:wawu_mobile/screens/wawu_africa/sign_up/sign_up.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/providers/notification_provider.dart';
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

  List<Widget> _screens = [];
  List<CustomNavItem> _customNavItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreensAndNavItems();
      _performInitialSubscriptionCheck();
      _requestMicrophonePermission();
    });
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
              message: 'Microphone permission denied. Voice features will be limited.',
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

  // /// Show dialog to direct user to settings for microphone permission
  // void _showPermissionSettingsDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Microphone Permission Required'),
  //         content: const Text(
  //           'To use voice features, please enable microphone permission in your device settings.',
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('Cancel'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               openAppSettings();
  //             },
  //             child: const Text('Open Settings'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  /// Check microphone permission status
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  // /// Request microphone permission when needed for specific features
  // Future<bool> requestMicrophonePermissionForFeature(String featureName) async {
  //   final status = await Permission.microphone.status;
    
  //   if (status.isGranted) {
  //     return true;
  //   }
    
  //   if (status.isDenied) {
  //     final result = await Permission.microphone.request();
      
  //     if (result.isGranted) {
  //       if (mounted) {
  //         CustomSnackBar.show(
  //           context,
  //           message: 'Microphone permission granted for $featureName',
  //           isError: false,
  //         );
  //       }
  //       return true;
  //     } else if (result.isPermanentlyDenied) {
  //       if (mounted) {
  //         _showPermissionSettingsDialog();
  //       }
  //       return false;
  //     }
  //   } else if (status.isPermanentlyDenied) {
  //     if (mounted) {
  //       _showPermissionSettingsDialog();
  //     }
  //     return false;
  //   }
    
  //   if (mounted) {
  //     CustomSnackBar.show(
  //       context,
  //       message: 'Microphone permission is required for $featureName',
  //       isError: true,
  //     );
  //   }
  //   return false;
  // }

  /// Perform initial subscription check - optimized to prevent repeated redirects
// Fixed MainScreen _performInitialSubscriptionCheck method
void _performInitialSubscriptionCheck() async {
  if (_hasCheckedSubscription || _subscriptionCheckInProgress) return;

  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final currentUser = userProvider.currentUser;
  final userType = currentUser?.role?.toLowerCase();

  // Skip subscription check for BUYER role or unauthenticated users
  if (userType == 'buyer' || currentUser == null) {
    debugPrint('[MainScreen] Skipping subscription check - BUYER role or no user');
    setState(() {
      _hasCheckedSubscription = true;
    });
    return;
  }

  setState(() {
    _subscriptionCheckInProgress = true;
  });

  try {
    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    
    // First, try to load cached subscription (fastest method)
    final bool hasCachedSubscription = await planProvider.loadCachedSubscription(currentUser.uuid);
    
    if (hasCachedSubscription && mounted) {
      debugPrint('[MainScreen] Found cached subscription, no need for further checks');
      setState(() {
        _hasCheckedSubscription = true;
        _subscriptionCheckInProgress = false;
      });
      return;
    }

    // Check network connectivity before making API calls
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('[MainScreen] No internet connection, allowing user to stay');
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'No internet connection. Some features may be limited.',
          isError: true,
        );
        setState(() {
          _hasCheckedSubscription = true;
          _subscriptionCheckInProgress = false;
        });
      }
      return;
    }

    // Initialize IAP if not already done
    if (!planProvider.isIapInitialized) {
      final bool iapInitialized = await planProvider.initializeIAP();
      if (!iapInitialized && mounted) {
        debugPrint('[MainScreen] IAP initialization failed, but allowing user to continue');
        setState(() {
          _hasCheckedSubscription = true;
          _subscriptionCheckInProgress = false;
        });
        return;
      }
    }

    // After IAP initialization, check subscription status
    final bool hasActiveSubscription = await planProvider.checkActiveSubscription();
    
    if (mounted) {
      if (hasActiveSubscription) {
        debugPrint('[MainScreen] Active subscription confirmed');
        setState(() {
          _hasCheckedSubscription = true;
          _subscriptionCheckInProgress = false;
        });
      } else {
        // Only redirect if we're certain there's no active subscription
        debugPrint('[MainScreen] No active subscription found, redirecting to plan screen');
        setState(() {
          _subscriptionCheckInProgress = false;
        });
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Plan()),
        );
        return;
      }
    }

  } catch (e) {
    debugPrint('[MainScreen] Error during subscription check: $e');
    if (mounted) {
      setState(() {
        _hasCheckedSubscription = true;
        _subscriptionCheckInProgress = false;
      });
      CustomSnackBar.show(
        context,
        message: 'Unable to verify subscription. You can continue using the app.',
        isError: false,
      );
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
        const HomeScreen(),
        const BlogScreen(),
        const MessagesScreen(),
        if (!isBuyer) const GigsScreen(),
        const SettingsScreen(),
      ];

      _customNavItems = [
        CustomNavItem(iconPath: 'assets/images/svg/home.svg', label: 'Home'),
        CustomNavItem(iconPath: 'assets/images/svg/blog.svg', label: 'Blog'),
        CustomNavItem(
          iconPath: 'assets/images/svg/message.svg',
          label: 'Messages',
        ),
        if (!isBuyer)
          CustomNavItem(iconPath: 'assets/images/svg/gigs.svg', label: 'Gigs'),
        CustomNavItem(
          iconPath: 'assets/images/svg/settings.svg',
          label: 'Settings',
        ),
      ];

      if (_selectedIndex >= _screens.length) {
        _selectedIndex = 0;
      }
    });
  }

  Widget _buildProfileImage(String? profileImageUrl) {
    if (profileImageUrl != null && profileImageUrl.startsWith('http')) {
      return CachedNetworkImage(
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

  List<Widget> _getAppBarTitles() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final List<Widget> titles = [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildProfileImage(userProvider.currentUser?.profileImage),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userProvider.currentUser != null
                    ? "Hello ${userProvider.currentUser?.firstName}"
                    : "Hello Guest",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                "Find Your Gig Today",
                style: TextStyle(fontSize: 11, color: wawuColors.buttonPrimary),
              ),
            ],
          ),
        ],
      ),
      const Text(
        'Blog',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const Text(
        'Messages',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const Text(
        'Gigs',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const Text(
        'Settings',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ];

    final currentUser = userProvider.currentUser;
    final isBuyer = currentUser?.role?.toUpperCase() == 'BUYER';

    List<Widget> actualTitles = [];
    actualTitles.add(titles[0]); // Home
    actualTitles.add(titles[1]); // Blog
    actualTitles.add(titles[2]); // Messages
    if (!isBuyer && currentUser != null) {
      actualTitles.add(titles[3]); // Gigs
    }
    actualTitles.add(titles[4]); // Settings

    return actualTitles;
  }

  void _onItemTapped(int index) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    // Allow Home (0) and Blog (1) for unauthenticated users
    if (currentUser == null && index != 0 && index != 1) {
      _showAuthModal();
      return;
    }

    setState(() {
      _selectedIndex = index;
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

  List<Widget> _getAppBarActions() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser != null) {
      return [_buildNotificationsButton()];
    } else {
      return [];
    }
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

  Widget _buildNotificationsButton() {
    return Consumer2<NotificationProvider, UserProvider>(
      builder: (context, notificationProvider, userProvider, _) {
        final unreadCount = notificationProvider.unreadCount;
        final hasUnread = unreadCount > 0;

        return Container(
          decoration: BoxDecoration(
            color: wawuColors.purpleDarkestContainer,
            shape: BoxShape.circle,
          ),
          margin: const EdgeInsets.only(right: 10),
          height: 36,
          width: 36,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications,
                  size: 17,
                  color: Colors.white,
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
    final List<Widget> appBarTitles = _getAppBarTitles();

    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final isBlocked = userProvider.currentUser?.status == 'BLOCKED';

        if (isBlocked) return const BlockedAccountOverlay();

        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [appBarTitles[_selectedIndex]],
                ),
                centerTitle: false,
                automaticallyImplyLeading: false,
                actions: _getAppBarActions(),
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
                          'Verifying subscription...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
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