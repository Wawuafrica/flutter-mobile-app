// import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:wawu_mobile/providers/her_purchase_provider.dart';
import 'package:wawu_mobile/providers/wawu_africa_provider.dart';
import 'providers/network_status_provider.dart';
import 'package:wawu_mobile/providers/ad_provider.dart';
import 'package:wawu_mobile/providers/skill_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

// Services
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/pusher_service.dart';
import 'services/socket_service.dart'; // Import the new SocketService

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
import 'package:wawu_mobile/services/onboarding_state_service.dart';
import 'package:wawu_mobile/screens/account_type/account_type.dart';
import 'package:wawu_mobile/screens/category_selection/category_selection.dart';
import 'package:wawu_mobile/screens/category_selection/sub_category_selection.dart';
import 'package:wawu_mobile/screens/update_profile/update_profile.dart';
import 'package:wawu_mobile/screens/update_profile/profile_update/profile_update.dart';
import 'package:wawu_mobile/screens/plan/plan.dart';
import 'package:wawu_mobile/screens/account_payment/disclaimer/disclaimer.dart';
import 'package:wawu_mobile/screens/wawu_africa/sign_up/otp_screen.dart';

// Initialize Logger
final _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 220,
    colors: true,
    printEmojis: true,
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SharedPreferences.getInstance();
  } catch (e) {
    _logger.e('Main: Error initializing SharedPreferences: $e');
  }

  _logger.i('Main: App startup initiated.');

  try {
    await dotenv.load(fileName: ".env");
    _logger.i('Main: Environment variables loaded successfully.');
  } catch (e) {
    _logger.e('Main: Error loading .env file: $e.');
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Fatal Error: Failed to load configuration.'),
          ),
        ),
      ),
    );
    return;
  }

  final apiService = ApiService();
  final authService = AuthService(apiService: apiService);
  final pusherService = PusherService();
  final socketService = SocketService(); // Instantiate the new SocketService

  try {
    await apiService.initialize(
      apiBaseUrl:
          dotenv.env['API_BASE_URL'] ?? 'https://production.wawuafrica.com/api',
      authService: authService,
    );
    _logger.i('Main: ApiService initialized.');

    await pusherService.initialize();
    _logger.i('Main: PusherService initialized.');

    await authService.init();
    _logger.i('Main: AuthService initialized.');

    // Initialize SocketService with token if available
    if (authService.isAuthenticated && authService.token != null) {
      socketService.initializeSocket(authService.token!);
    }

    runApp(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: apiService),
          Provider<AuthService>.value(value: authService),
          Provider<PusherService>.value(value: pusherService),
          Provider<SocketService>.value(
            value: socketService,
          ), // Provide SocketService
          ChangeNotifierProvider(create: (context) => NetworkStatusProvider()),
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
          // CORRECTED: WawuAfricaProvider now correctly receives the SocketService
          ChangeNotifierProxyProvider<UserProvider, WawuAfricaProvider>(
            create:
                (context) => WawuAfricaProvider(
                  apiService: apiService,
                  userProvider: Provider.of<UserProvider>(
                    context,
                    listen: false,
                  ),
                  socketService: Provider.of<SocketService>(
                    context,
                    listen: false,
                  ),
                ),
            update:
                (context, userProvider, previous) =>
                    previous ??
                    WawuAfricaProvider(
                      apiService: apiService,
                      userProvider: userProvider,
                      socketService: socketService,
                    ),
          ),
          ChangeNotifierProvider(
            create: (context) => HerPurchaseProvider(apiService: apiService),
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
      'Main: Fatal error during app initialization.',
      error: e,
      stackTrace: st,
    );
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Failed to initialize app. Error: $e')),
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
  bool _isSplashTimerFinished = false;
  bool _isOfflineNotificationShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isSplashTimerFinished = true);
    });
  }

  Future<void> _initializeApp() async {
    try {
      if (!mounted) return;
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      Widget initialScreen;
      if (!authService.isAuthenticated ||
          currentUser == null ||
          currentUser.uuid.isEmpty) {
        initialScreen = const MainScreen();
      } else {
        final shouldShowOnboarding =
            await OnboardingStateService.shouldShowOnboarding();
        if (shouldShowOnboarding) {
          final onboardingStep = await OnboardingStateService.getStep();
          switch (onboardingStep) {
            case 'otp':
              initialScreen = OtpScreen(
                authService: authService,
                email: currentUser.email!,
              );
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
                  categoryId != null
                      ? SubCategorySelection(categoryId: categoryId)
                      : const AccountType();
              break;
            case 'update_profile':
              initialScreen = const UpdateProfile();
              break;
            case 'profile_update':
              initialScreen = const ProfileUpdate();
              break;
            case 'plan':
            case 'payment':
            case 'payment_processing':
            case 'verify_payment':
              initialScreen = Plan();
              break;
            case 'disclaimer':
              initialScreen = const Disclaimer();
              break;

            default:
              initialScreen = const AccountType();
          }
        } else {
          initialScreen = const MainScreen();
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
        'MyApp: Error during app initialization.',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        setState(() {
          _currentScreen = const MainScreen();
          _isInitialized = true;
        });
      }
    }
  }

  void _handleNetworkStatusChange(NetworkStatusProvider networkStatus) {
    if (!_isInitialized) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isOfflineNotificationShown = !networkStatus.isOnline);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Potentially re-check connections or refresh data
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper.builder(
      BouncingScrollWrapper.builder(
        context,
        MaterialApp(
          title: 'WAWUAfrica',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            textTheme: GoogleFonts.soraTextTheme(Theme.of(context).textTheme),
            colorScheme: ColorScheme.fromSeed(seedColor: wawuColors.primary),
            useMaterial3: true,
          ),
          home: Consumer<NetworkStatusProvider>(
            builder: (context, networkStatus, child) {
              _handleNetworkStatusChange(networkStatus);
              return Stack(
                children: [
                  _isInitialized &&
                          _isSplashTimerFinished &&
                          _currentScreen != null
                      ? _currentScreen!
                      : Scaffold(
                        body: Center(
                          child: Image.asset('assets/none.png', width: 260),
                        ),
                      ),
                  if (_isOfflineNotificationShown)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Material(
                        color: Colors.red,
                        child: SafeArea(
                          child: Container(
                            padding: const EdgeInsets.all(12),
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
                                  style: TextStyle(color: Colors.white),
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
      breakpoints: const [
        ResponsiveBreakpoint.resize(320, name: MOBILE),
        ResponsiveBreakpoint.resize(480, name: MOBILE),
        ResponsiveBreakpoint.resize(600, name: TABLET),
        ResponsiveBreakpoint.resize(800, name: TABLET),
        ResponsiveBreakpoint.resize(1000, name: DESKTOP),
      ],
      defaultScale: true,
    );
  }
}
