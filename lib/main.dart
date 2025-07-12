// import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'providers/network_status_provider.dart';
import 'package:wawu_mobile/providers/ad_provider.dart';
import 'package:wawu_mobile/providers/skill_provider.dart';
import 'package:wawu_mobile/screens/wawu/wawu.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:wawu_mobile/screens/wawu_merch/wawu_merch_main.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
// import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
// import 'package:flutter/foundation.dart'; // Import for compute

// Services
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/pusher_service.dart';

// Providers
import 'providers/blog_provider.dart';
import 'providers/links_provider.dart';
import 'providers/location_provider.dart';
import 'providers/category_provider.dart';
import 'providers/gig_provider.dart';
import 'providers/message_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/dropdown_data_provider.dart';
import 'providers/product_provider.dart';
import 'providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import your new screens
import 'package:wawu_mobile/screens/main_screen/main_screen.dart';
import 'package:wawu_mobile/widgets/in_app_notifications.dart';
import 'package:wawu_mobile/services/onboarding_state_service.dart';
import 'package:wawu_mobile/screens/account_type/account_type.dart';
import 'package:wawu_mobile/screens/category_selection/category_selection.dart';
import 'package:wawu_mobile/screens/category_selection/sub_category_selection.dart';
import 'package:wawu_mobile/screens/update_profile/update_profile.dart';
import 'package:wawu_mobile/screens/update_profile/profile_update/profile_update.dart';
import 'package:wawu_mobile/screens/plan/plan.dart';
import 'package:wawu_mobile/screens/account_payment/account_payment.dart';
import 'package:wawu_mobile/screens/account_payment/disclaimer/disclaimer.dart';
import 'package:wawu_mobile/screens/wawu_africa/sign_up/otp_screen.dart';

// Initialize Logger
final _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0, // No method calls to be displayed
    errorMethodCount: 8, // Number of method calls if stacktrace is provided
    lineLength: 120, // Width of the output
    colors: true, // Colorful log messages
    printEmojis: true, // Print an emoji for each log message
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SharedPreferences.getInstance(); // Initialize SharedPreferences
  } catch (e) {
    debugPrint('Error initializing SharedPreferences: $e');
    _logger.e('Main: Error initializing SharedPreferences: $e');
  }

  _logger.i('Main: App startup initiated.');

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    _logger.i('Main: Environment variables loaded successfully.');
  } catch (e) {
    _logger.e(
      'Main: Error loading .env file: $e. Ensure .env file exists and is accessible.',
    );

    // // Initialize WebView for iOS
    // if (Platform.isIOS) {
    //   // WebView.platform = SurfaceWebViewPlatform();
    //   // WebView.platform = WebKitWebViewPlatform();
    // }

    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Fatal Error: Failed to load configuration. Please contact support.',
            ),
          ),
        ),
      ),
    );
    return;
  }

  _logger.d('Main: Instantiating core services...');
  final apiService = ApiService();
  final authService = AuthService(apiService: apiService);
  final pusherService = PusherService();

  try {
    _logger.d('Main: Initializing ApiService...');
    await apiService.initialize(
      apiBaseUrl:
          dotenv.env['API_BASE_URL'] ?? 'https://staging.wawuafrica.com/api',
      authService: authService,
    );
    _logger.i('Main: ApiService initialized.');

    _logger.d('Main: Initializing PusherService...');
    await pusherService.initialize();
    _logger.i(
      'Main: PusherService initialized successfully and connection attempted.',
    );

    _logger.d('Main: Initializing AuthService and loading user data...');
    await authService.init();
    _logger.i('Main: AuthService initialized and user data loaded.');

    _logger.d('Main: Running MyApp with MultiProvider...');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<NetworkStatusProvider>(
            create: (_) => NetworkStatusProvider(),
          ),
          Provider<ApiService>.value(value: apiService),
          Provider<AuthService>.value(value: authService),
          Provider<PusherService>.value(value: pusherService),
          ChangeNotifierProvider(
            create:
                (context) => UserProvider(
                  apiService: apiService,
                  authService: authService,
                  pusherService: pusherService,
                ),
          ),
          ChangeNotifierProvider(
            create:
                (context) => BlogProvider(
                  apiService: apiService,
                  pusherService: pusherService,
                ),
          ),
          ChangeNotifierProvider(
            create:
                (context) => AdProvider(
                  apiService: apiService,
                  pusherService: pusherService,
                ),
          ),
          ChangeNotifierProxyProvider<UserProvider, MessageProvider>(
            create:
                (context) => MessageProvider(
                  apiService: apiService,
                  userProvider: Provider.of<UserProvider>(
                    context,
                    listen: false,
                  ),
                  pusherService: pusherService,
                ),
            update:
                (context, userProvider, messageProvider) =>
                    messageProvider ??
                    MessageProvider(
                      apiService: apiService,
                      userProvider: userProvider,
                      pusherService: pusherService,
                    ),
          ),
          ChangeNotifierProvider(
            create:
                (context) => NotificationProvider(
                  apiService: apiService,
                  pusherService: pusherService,
                ),
          ),
          ChangeNotifierProxyProvider<UserProvider, GigProvider>(
            create:
                (context) => GigProvider(
                  apiService: apiService,
                  pusherService: pusherService,
                  userProvider: Provider.of<UserProvider>(
                    context,
                    listen: false,
                  ),
                ),
            update:
                (context, userProvider, gigProvider) =>
                    gigProvider ??
                    GigProvider(
                      apiService: apiService,
                      pusherService: pusherService,
                      userProvider: userProvider,
                    ),
          ),
          ChangeNotifierProvider(
            create:
                (context) => ProductProvider(
                  apiService: apiService,
                  pusherService: pusherService,
                ),
          ),
          ChangeNotifierProvider(
            create: (context) => CategoryProvider(apiService: apiService),
          ),
          ChangeNotifierProvider(
            create: (context) => PlanProvider(apiService: apiService),
          ),
          ChangeNotifierProvider(
            create: (context) => DropdownDataProvider(apiService: apiService),
          ),
          ChangeNotifierProvider(
            create: (context) => LocationProvider(apiService: apiService),
          ),
          ChangeNotifierProvider(
            create:
                (context) =>
                    LinksProvider(apiService: apiService)..fetchLinks(),
          ),
          ChangeNotifierProvider(
            create:
                (context) => SkillProvider(
                  apiService: Provider.of<ApiService>(context, listen: false),
                ),
          ),
        ],
        child: MyApp(pusherService: pusherService),
      ),
    );
  } catch (e, st) {
    _logger.e(
      'Main: Fatal error during app initialization. Showing fallback UI.',
      error: e,
      stackTrace: st,
    );
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Failed to initialize app. Please restart or contact support. Error: $e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final PusherService pusherService;

  const MyApp({super.key, required this.pusherService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isInitialized = false;
  Widget? _currentScreen;
  bool _isRefreshingData = false;
  Timer? _reconnectionDebouncer;

  // Tracks if the "No internet connection" notification is currently shown
  bool _isOfflineNotificationShown = false;
  // Tracks if the "You're back online!" notification has been shown recently
  bool _hasShownReconnectionNotification = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _logger.d('MyApp: App state initialized');
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(
        const Duration(milliseconds: 2000),
      ); // Splash minimum duration

      if (!mounted) return;

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      Widget initialScreen;

      if (!authService.isAuthenticated ||
          currentUser == null ||
          currentUser.uuid.isEmpty) {
        _logger.i(
          'MyApp: User not authenticated or missing UUID. Showing Wawu screen.',
        );
        initialScreen = const Wawu();
      } else {
        final userRole = currentUser.role?.toUpperCase();
        final shouldShowOnboarding =
            await OnboardingStateService.shouldShowOnboarding();
        final debugState = await OnboardingStateService.getDebugState();
        _logger.i('MyApp: Onboarding debug state: $debugState');
        _logger.i(
          'MyApp: User role: $userRole, Should show onboarding: $shouldShowOnboarding',
        );

        if (shouldShowOnboarding) {
          final onboardingStep = await OnboardingStateService.getStep();
          _logger.i(
            'MyApp: User onboarding in progress. Step: $onboardingStep',
          );

          switch (onboardingStep) {
            case 'otp':
              if (currentUser.email != null) {
                initialScreen = OtpScreen(
                  authService: authService,
                  email: currentUser.email!,
                );
              } else {
                initialScreen = const AccountType();
              }
              break;
            case 'account_type':
              initialScreen = const AccountType();
              break;
            case 'category_selection':
              initialScreen = const CategorySelection();
              break;
            case 'subcategory_selection':
              final categoryId = await OnboardingStateService.getCategory();
              initialScreen =
                  (categoryId != null && categoryId.isNotEmpty)
                      ? SubCategorySelection(categoryId: categoryId)
                      : const AccountType(); // Fallback
              break;
            case 'update_profile':
              initialScreen = const UpdateProfile();
              break;
            case 'profile_update':
              initialScreen = const ProfileUpdate();
              break;
            case 'plan':
              initialScreen = const Plan();
              break;
            case 'payment':
            case 'payment_processing':
            case 'verify_payment':
              initialScreen = AccountPayment(userId: currentUser.uuid);
              break;
            case 'disclaimer':
              initialScreen = const Disclaimer();
              break;
            default:
              _logger.w(
                'MyApp: Unknown onboarding step: $onboardingStep. Defaulting to AccountType.',
              );
              initialScreen = const AccountType();
          }
        } else {
          if (userRole == 'SELLER' ||
              userRole == 'BUYER' ||
              userRole == 'PROFESSIONAL' ||
              userRole == 'ARTISAN') {
            _logger.i(
              'MyApp: User authenticated with role $userRole. Navigating to MainScreen.',
            );
            initialScreen = const MainScreen();
          } else {
            _logger.i(
              'MyApp: User authenticated with role $userRole. Navigating to WawuMerchMain.',
            );
            initialScreen = const WawuMerchMain();
          }
        }
      }

      if (mounted) {
        setState(() {
          _currentScreen = initialScreen;
          _isInitialized = true;
        });
      }
    } catch (e, st) {
      _logger.e(
        'MyApp: Error during app initialization. Showing Wawu screen as fallback.',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        setState(() {
          _currentScreen = const Wawu();
          _isInitialized = true;
        });
      }
    }
  }

  // --- Network Connection Handling ---

  void _handleNetworkStatusChange(NetworkStatusProvider networkStatus) {
    if (!_isInitialized) return; // Only process after initial app load

    if (!networkStatus.isOnline && _isOfflineNotificationShown == false) {
      // Show "No internet" if currently online and not already shown
      setState(() {
        _isOfflineNotificationShown = true;
      });
      _logger.i(
        'MyApp: Network went offline. Displaying "No internet" banner.',
      );
      // Cancel any pending reconnection debouncer if we go offline
      _reconnectionDebouncer?.cancel();
      _isRefreshingData = false; // Reset refresh flag
      _hasShownReconnectionNotification =
          false; // Allow reconnection notification to show again
    } else if (networkStatus.isOnline && networkStatus.wasOffline) {
      // Network reconnected (was offline, now online)
      _logger.d(
        'MyApp: Network status indicates reconnection (was offline, now online).',
      );
      if (_isOfflineNotificationShown) {
        setState(() {
          _isOfflineNotificationShown = false;
        });
        _logger.i('MyApp: Network reconnected. Hiding "No internet" banner.');
      }
      _handleNetworkReconnection();
    } else if (networkStatus.isOnline &&
        !networkStatus.wasOffline &&
        _isOfflineNotificationShown) {
      // Case where it comes online but wasn't explicitly "offline" (e.g., initial load was offline)
      // Hide the banner if it's showing and we're online
      setState(() {
        _isOfflineNotificationShown = false;
      });
      _logger.i(
        'MyApp: Network is online. Hiding "No internet" banner if shown.',
      );
    }
  }

  void _handleNetworkReconnection() {
    _reconnectionDebouncer?.cancel(); // Cancel any existing debouncer

    _reconnectionDebouncer = Timer(const Duration(seconds: 3), () {
      // Debounce for 3 seconds to ensure stable connection
      if (!mounted) return;

      if (!_isRefreshingData) {
        _isRefreshingData = true;
        _hasShownReconnectionNotification = false;
        _showReconnectionNotification(); // Show notification
        _logger.i(
          'MyApp: Network reconnected. Re-engaging services and refreshing data...',
        );

        _handlePusherReconnection();

        _refreshProvidersOptimized().whenComplete(() {
          if (mounted) {
            _isRefreshingData = false;
            _logger.i(
              'MyApp: Network reconnection and data refresh process completed.',
            );
          }
        });
      }
    });
  }

  void _showReconnectionNotification() {
    if (_hasShownReconnectionNotification) return;

    // _hasShownReconnectionNotification = true;

    if (mounted) {
      showNotification(
        "✨ You're back online! Wawu is syncing your world. ✨",
        context,
        backgroundColor: Colors.green,
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }

    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _hasShownReconnectionNotification = false;
      }
    });
  }

  void _handlePusherReconnection() {
    if (widget.pusherService.isInitialized) {
      _logger.d(
        'MyApp: PusherService is initialized, calling resubscribeToChannels.',
      );
      try {
        widget.pusherService.resubscribeToChannels();
      } catch (e) {
        _logger.e('MyApp: Error resubscribing to Pusher channels: $e');
      }
    } else {
      _logger.w(
        'MyApp: PusherService is not initialized. Attempting to re-initialize.',
      );
      widget.pusherService
          .initialize()
          .then((_) {
            _logger.i(
              'MyApp: PusherService successfully re-initialized after network recovery.',
            );
          })
          .catchError((e) {
            _logger.e(
              'MyApp: Failed to re-initialize PusherService on network recovery: $e',
            );
          });
    }
  }

  Future<void> _refreshProvidersOptimized() async {
    if (!mounted) return;

    _logger.i(
      'MyApp: Starting optimized data refresh after network reconnection',
    );

    final List<Future<void> Function()> refreshTasks = [
      () => _refreshUserProviderSafe(),
      () => _refreshMessageProviderSafe(),
      () => _refreshCategoryProviderSafe(),
      () => _refreshBlogProviderSafe(),
      () => _refreshProductProviderSafe(),
      () => _refreshPlanProviderSafe(),
      () => _refreshDropdownProviderSafe(),
      () => _refreshGigProviderSafe(),
      () => _refreshAdProviderSafe(),
      () => _refreshNotificationProviderSafe(),
      () => _refreshLocationProviderSafe(),
      () => _refreshSkillProviderSafe(),
      () => _refreshLinksProviderSafe(),
    ];

    for (var task in refreshTasks) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 50));
      await task();
    }

    _logger.i('MyApp: Optimized provider refresh completed successfully');
  }

  Future<void> _refreshLocationProviderSafe() async {
    if (!mounted) return;
    try {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      await locationProvider.fetchCountries();
      _logger.d('MyApp: LocationProvider refreshed successfully');
    } catch (e, st) {
      _logger.e(
        'MyApp: Error refreshing LocationProvider: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _refreshSkillProviderSafe() async {
    if (!mounted) return;
    try {
      final skillProvider = Provider.of<SkillProvider>(context, listen: false);
      await skillProvider.fetchSkills();
      _logger.d('MyApp: SkillProvider refreshed successfully');
    } catch (e, st) {
      _logger.e(
        'MyApp: Error refreshing SkillProvider: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _refreshLinksProviderSafe() async {
    if (!mounted) return;
    try {
      final linksProvider = Provider.of<LinksProvider>(context, listen: false);
      await linksProvider.fetchLinks();
      _logger.d('MyApp: LinksProvider refreshed successfully');
    } catch (e, st) {
      _logger.e(
        'MyApp: Error refreshing LinksProvider: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _refreshUserProviderSafe() async {
    if (!mounted) return;
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;
      if (currentUser != null && currentUser.uuid.isNotEmpty) {
        await userProvider
            .fetchUserById(currentUser.uuid)
            .timeout(const Duration(seconds: 10));
        _logger.d('MyApp: UserProvider refreshed successfully');
      }
    } catch (e, st) {
      _logger.e(
        'MyApp: Error refreshing UserProvider: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _refreshMessageProviderSafe() async {
    if (!mounted) return;
    try {
      final messageProvider = Provider.of<MessageProvider>(
        context,
        listen: false,
      );
      await messageProvider.fetchConversations().timeout(
        const Duration(seconds: 15),
      );
      _logger.d('MyApp: MessageProvider refreshed successfully');
    } catch (e, st) {
      _logger.e(
        'MyApp: Error refreshing MessageProvider: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _refreshCategoryProviderSafe() async {
    if (!mounted) return;
    try {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      await categoryProvider.fetchCategories().timeout(
        const Duration(seconds: 10),
      );
      _logger.d('MyApp: CategoryProvider refreshed successfully');
    } catch (e, st) {
      _logger.e(
        'MyApp: Error refreshing CategoryProvider: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _refreshBlogProviderSafe() async {
    if (!mounted) return;
    try {
      final blogProvider = Provider.of<BlogProvider>(context, listen: false);
      await blogProvider
          .fetchPosts(refresh: true)
          .timeout(const Duration(seconds: 15));
      _logger.d('MyApp: BlogProvider refreshed successfully');
    } catch (e, st) {
      _logger.e(
        'MyApp: Error refreshing BlogProvider: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _refreshProductProviderSafe() async {
    if (!mounted) return;
    try {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      await Future.wait([
        productProvider.fetchFeaturedProducts().timeout(
          const Duration(seconds: 10),
        ),
        productProvider
            .fetchProducts(refresh: true)
            .timeout(const Duration(seconds: 15)),
      ], eagerError: false);
      _logger.d('MyApp: ProductProvider refreshed successfully');
    } catch (e, st) {
      _logger.e(
        'MyApp: Error refreshing ProductProvider: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _refreshPlanProviderSafe() async {
    if (!mounted) return;
    try {
      final planProvider = Provider.of<PlanProvider>(context, listen: false);
      await planProvider.fetchAllPlans().timeout(const Duration(seconds: 10));
      _logger.d('MyApp: PlanProvider refreshed successfully');
    } catch (e, st) {
      _logger.e(
        'MyApp: Error refreshing PlanProvider: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _refreshDropdownProviderSafe() async {
    if (!mounted) return;
    try {
      final dropdownProvider = Provider.of<DropdownDataProvider>(
        context,
        listen: false,
      );
      await dropdownProvider.fetchDropdownData().timeout(
        const Duration(seconds: 10),
      );
      _logger.d('MyApp: DropdownDataProvider refreshed successfully');
    } catch (e, st) {
      _logger.e(
        'MyApp: Error refreshing DropdownDataProvider: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _refreshGigProviderSafe() async {
    if (!mounted) return;
    try {
      final gigProvider = Provider.of<GigProvider>(context, listen: false);
      await gigProvider.fetchGigs().timeout(const Duration(seconds: 15));
      _logger.d('MyApp: GigProvider refreshed successfully');
    } catch (e, st) {
      _logger.e(
        'MyApp: Error refreshing GigProvider: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _refreshAdProviderSafe() async {
    if (!mounted) return;
    try {
      final adProvider = Provider.of<AdProvider>(context, listen: false);
      await adProvider.refresh().timeout(const Duration(seconds: 10));
      _logger.d('MyApp: AdProvider refreshed successfully');
    } catch (e, st) {
      _logger.e(
        'MyApp: Error refreshing AdProvider: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _refreshNotificationProviderSafe() async {
    if (!mounted) return;
    try {
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;
      if (currentUser != null && currentUser.uuid.isNotEmpty) {
        await notificationProvider.refreshNotifications().timeout(
          const Duration(seconds: 10),
        );
        _logger.d('MyApp: NotificationProvider refreshed successfully');
      }
    } catch (e, st) {
      _logger.e(
        'MyApp: Error refreshing NotificationProvider: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  void dispose() {
    _logger.d('MyApp: Disposing of WidgetsBindingObserver.');
    WidgetsBinding.instance.removeObserver(this);
    _reconnectionDebouncer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.d('MyApp: App lifecycle state changed to: $state');
    if (state == AppLifecycleState.resumed) {
      _logger.i('MyApp: App resumed.');
      // The NetworkStatusProvider will automatically handle connectivity checks
      // and trigger the reconnection logic via the Consumer if needed.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper.builder(
      BouncingScrollWrapper.builder(
        context,
        MaterialApp(
          title: 'Wawu Mobile',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            textTheme: GoogleFonts.soraTextTheme(Theme.of(context).textTheme),
            primaryTextTheme: GoogleFonts.soraTextTheme(
              Theme.of(context).primaryTextTheme,
            ),
            colorScheme: ColorScheme.fromSeed(seedColor: wawuColors.primary),
            useMaterial3: true,
          ),
          home: Consumer<NetworkStatusProvider>(
            builder: (context, networkStatus, child) {
              // Trigger network status handling logic
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _handleNetworkStatusChange(networkStatus);
              });

              return Stack(
                children: [
                  _isInitialized && _currentScreen != null
                      ? _currentScreen!
                      : const SplashScreen(),
                  // Only show the "No internet connection" banner if it's explicitly marked to be shown
                  if (_isOfflineNotificationShown)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Material(
                        color: Colors.red,
                        elevation: 4,
                        child: SafeArea(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.wifi_off,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'No internet connection',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      breakpoints: [
        // Small phones (iPhone SE, older Android phones)
        const ResponsiveBreakpoint.resize(280, name: MOBILE),
        const ResponsiveBreakpoint.resize(300, name: MOBILE),
        const ResponsiveBreakpoint.resize(320, name: MOBILE),

        // Standard phones (iPhone 12, 13, 14, Samsung Galaxy S series)
        const ResponsiveBreakpoint.resize(375, name: MOBILE),

        // Large phones (iPhone Pro Max, Samsung Galaxy Note, Z Fold outer screen)
        const ResponsiveBreakpoint.resize(428, name: MOBILE),

        // Extra large phones and foldables
        const ResponsiveBreakpoint.resize(480, name: MOBILE),

        // Small tablets and foldables inner screen
        const ResponsiveBreakpoint.resize(600, name: TABLET),

        // Standard tablets
        const ResponsiveBreakpoint.resize(768, name: TABLET),

        // Large tablets
        const ResponsiveBreakpoint.resize(1024, name: TABLET),

        // Desktop
        const ResponsiveBreakpoint.resize(1200, name: DESKTOP),
      ],
      // Enable default scaling behavior
      defaultScale: true,

      // Set minimum width to handle very small screens
      minWidth: 280,

      // Set maximum width to prevent over-scaling on very large screens
      maxWidth: 1200,

      // Default name for smallest screens
      defaultName: MOBILE,

      // Enable automatic scaling for better text and component sizing
      mediaQueryData: MediaQueryData.fromView(
        WidgetsBinding.instance.platformDispatcher.views.first,
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: wawuColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo2.png', width: 180, cacheWidth: 400),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: 300,
                child: Text(
                  "Are you tired? Worn out? Burned out on getting the world to see you and pay you? Come to me. Get away with me and you'll recover your life. I'll show you how to take a real rest. Walk with me and work with me watch how I do it",
                  style: GoogleFonts.sora(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Matthew 11:28 MSG',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
