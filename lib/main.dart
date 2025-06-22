import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/network_status_provider.dart';
import 'package:wawu_mobile/providers/ad_provider.dart';
// import 'package:wawu_mobile/screens/account_type/account_type.dart';
// import 'package:wawu_mobile/screens/plan/plan.dart';
import 'package:wawu_mobile/screens/wawu/wawu.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async'; // Import for StreamSubscription
import 'package:logger/logger.dart'; // Import Logger
import 'package:wawu_mobile/screens/wawu_merch/wawu_merch_main.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

// Services
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/pusher_service.dart';

// Providers
import 'providers/blog_provider.dart';
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
import 'package:wawu_mobile/screens/main_screen/main_screen.dart'; // Assuming this path
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
    // Consider showing a fatal error screen here if env vars are critical
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
    return; // Stop execution
  }

  // Instantiate services early
  _logger.d('Main: Instantiating core services...');
  final apiService = ApiService();
  final authService = AuthService(apiService: apiService);
  final pusherService = PusherService(); // Get the singleton instance

  try {
    // Initialize ApiService first as AuthService depends on it
    _logger.d('Main: Initializing ApiService...');
    await apiService.initialize(
      apiBaseUrl:
          dotenv.env['API_BASE_URL'] ?? 'https://staging.wawuafrica.com/api',
      authService: authService,
    );
    _logger.i('Main: ApiService initialized.');

    // Initialize PusherService early in the app lifecycle
    _logger.d('Main: Initializing PusherService...');
    await pusherService.initialize();
    _logger.i(
      'Main: PusherService initialized successfully and connection attempted.',
    );

    // Initialize AuthService and load user data
    _logger.d('Main: Initializing AuthService and loading user data...');
    await authService.init(); // Load auth data here
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
          ChangeNotifierProvider(
            create:
                (context) => GigProvider(
                  apiService: apiService,
                  pusherService: pusherService,
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
    // Fallback UI if initialization fails
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
  // Track initialization state to prevent splash screen from showing again
  bool _isInitialized = false;
  Widget? _currentScreen;
  bool _hasShownReconnectNotification = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _logger.d('MyApp: App state initialized');

    // Initialize the app and determine the initial screen
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Show splash for minimum duration
      await Future.delayed(const Duration(milliseconds: 2000));

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
        final onboardingComplete = await OnboardingStateService.isComplete();

        // Debug logging to help troubleshoot onboarding state
        final debugState = await OnboardingStateService.getDebugState();
        _logger.i('MyApp: Onboarding debug state: $debugState');
        _logger.i(
          'MyApp: User role: $userRole, Onboarding complete: $onboardingComplete',
        );

        if (!onboardingComplete) {
          final onboardingStep = await OnboardingStateService.getStep();

          if (onboardingStep == null) {
            _logger.i(
              'MyApp: Onboarding step is null, treating as new onboarding.',
            );
            initialScreen = const AccountType();
          } else {
            switch (onboardingStep) {
              case 'account_type':
                initialScreen = const AccountType();
                break;
              case 'category_selection':
                initialScreen = const CategorySelection();
                break;
              case 'subcategory_selection':
                final categoryId = await OnboardingStateService.getCategory();
                if (categoryId != null && categoryId.isNotEmpty) {
                  initialScreen = SubCategorySelection(categoryId: categoryId);
                } else {
                  initialScreen = const AccountType();
                }
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
                _logger.w('MyApp: Unknown onboarding step: $onboardingStep');
                initialScreen = const AccountType();
            }
            _logger.i(
              'MyApp: User onboarding in progress. Step: $onboardingStep',
            );
          }
        } else if (userRole == 'SELLER' ||
            userRole == 'BUYER' ||
            userRole == 'PROFESSIONAL' ||
            userRole == 'ARTISAN') {
          _logger.i(
            'MyApp: User is authenticated with role $userRole. Navigating to MainScreen.',
          );
          initialScreen = const MainScreen();
        } else {
          _logger.i(
            'MyApp: User is authenticated with role $userRole. Navigating to WawuEcommerce.',
          );
          initialScreen = const WawuMerchMain();
        }
      }

      setState(() {
        _currentScreen = initialScreen;
        _isInitialized = true;
      });
    } catch (e) {
      _logger.e('MyApp: Error during app initialization: $e');
      setState(() {
        _currentScreen = const Wawu();
        _isInitialized = true;
      });
    }
  }

  void _handleNetworkReconnection() {
    if (!_isInitialized || _hasShownReconnectNotification) return;

    _hasShownReconnectNotification = true;

    // Reset the flag after a delay to allow future notifications
    Timer(const Duration(seconds: 5), () {
      _hasShownReconnectNotification = false;
    });

    _logger.i('MyApp: Network reconnected. Re-engaging services...');

    // Show reconnection notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showNotification(
          "✨ You're back online! Wawu is syncing your world. ✨",
          context,
          backgroundColor: wawuColors.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }
    });

    // Handle Pusher service reconnection
    if (widget.pusherService.isInitialized) {
      _logger.d(
        'MyApp: PusherService is initialized, calling resubscribeToChannels.',
      );
      widget.pusherService.resubscribeToChannels();
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

    // Refresh data from providers
    _refreshProvidersSafely();
  }

  Future<void> _refreshProvidersSafely() async {
    if (!mounted) return;

    // --- BlogProvider ---
    try {
      final blogProvider = Provider.of<BlogProvider>(context, listen: false);
      if (blogProvider.selectedPost != null) {
        await blogProvider.fetchPostById(blogProvider.selectedPost!.uuid);
      }
      await blogProvider.fetchPosts(refresh: true);
    } catch (e) {
      _logger.e('Error refreshing BlogProvider: $e');
    }

    // --- ProductProvider ---
    try {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      await productProvider.fetchFeaturedProducts();
      await productProvider.fetchProducts(refresh: true);
    } catch (e) {
      _logger.e('Error refreshing ProductProvider: $e');
    }

    // --- CategoryProvider ---
    try {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      await categoryProvider.fetchCategories();
    } catch (e) {
      _logger.e('Error refreshing CategoryProvider: $e');
    }

    // --- MessageProvider ---
    try {
      final messageProvider = Provider.of<MessageProvider>(
        context,
        listen: false,
      );
      await messageProvider.fetchConversations();
    } catch (e) {
      _logger.e('Error refreshing MessageProvider: $e');
    }

    // --- UserProvider ---
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;
      if (currentUser != null && currentUser.uuid.isNotEmpty) {
        await userProvider.fetchUserById(currentUser.uuid);
      }
    } catch (e) {
      _logger.e('Error refreshing UserProvider: $e');
    }

    // --- PlanProvider ---
    try {
      final planProvider = Provider.of<PlanProvider>(context, listen: false);
      await planProvider.fetchAllPlans();
    } catch (e) {
      _logger.e('Error refreshing PlanProvider: $e');
    }

    // --- DropdownDataProvider ---
    try {
      final dropdownProvider = Provider.of<DropdownDataProvider>(
        context,
        listen: false,
      );
      await dropdownProvider.fetchDropdownData();
    } catch (e) {
      _logger.e('Error refreshing DropdownDataProvider: $e');
    }
  }

  @override
  void dispose() {
    _logger.d('MyApp: Disposing of WidgetsBindingObserver.');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.d('MyApp: App lifecycle state changed to: $state');
    if (state == AppLifecycleState.resumed) {
      _logger.i('MyApp: App resumed. Checking for network changes.');
      // Let the NetworkStatusProvider handle connectivity checks
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
          // Handle reconnection when network comes back online
          if (networkStatus.hasInitialized && networkStatus.wasOffline) {
            _logger.d('MyApp: Network status indicates reconnection');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleNetworkReconnection();
            });
          }

          return Stack(
            children: [
              // Main app content
              _isInitialized && _currentScreen != null
                  ? _currentScreen!
                  : const SplashScreen(),

              // Offline indicator
              if (networkStatus.hasInitialized && !networkStatus.isOnline)
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            const Text(
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
    );
  }
}

// Your custom SplashScreen widget
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: wawuColors.white, // Or any color you prefer
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Translate the image down by 80-100 pixels (40-50% of typical screen center)
            Transform.translate(
              offset: const Offset(0, 10), // Adjust this value as needed
              child: Image.asset(
                'assets/logo2.png', // Replace with your actual logo path
                width: 200,
                cacheWidth: 800,
                height: 200,
              ),
            ),
            // const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
