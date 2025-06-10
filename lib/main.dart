import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/ad_provider.dart';
import 'package:wawu_mobile/screens/plan/plan.dart';
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
import 'providers/product_provider.dart';
import 'providers/user_provider.dart';

// Import your new screens
// import 'package:wawu_mobile/screens/main_screen/main_screen.dart'; // Assuming this path

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
          Provider<ApiService>.value(value: apiService),
          Provider<AuthService>.value(value: authService),
          Provider<PusherService>.value(
            value: pusherService,
          ), // Provide PusherService
          ChangeNotifierProvider(
            create:
                (context) => UserProvider(
                  authService: authService,
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
          ChangeNotifierProvider(
            create:
                (context) => MessageProvider(
                  apiService: apiService,
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
          // ChangeNotifierProvider(
          //   create:
          //       (context) => ApplicationProvider(
          //         apiService: apiService,
          //         pusherService: pusherService,
          //       ),
          // ),
          ChangeNotifierProvider(
            create:
                (context) => BlogProvider(
                  apiService: apiService,
                  pusherService: pusherService, // Uncomment if needed
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
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];

  // Future that completes when all initial data is loaded
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _logger.d('MyApp: Initializing connectivity monitoring...');
    _initConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );

    // Initialize the future that will determine the initial screen
    _initialization = _initializeAppDependencies();
  }

  Future<void> _initializeAppDependencies() async {
    // We already initialized services in main(), so here we just
    // ensure `AuthService.currentUser` is fully populated.
    // If you had other long-running setup tasks specific to UI here, you'd add them.
    // For now, we mainly rely on what's done in main().
    // You can add a small delay here if you want the splash screen to show for a minimum duration.
    await Future.delayed(
      const Duration(milliseconds: 1000),
    ); // Minimum 1.5 seconds splash

    // You might want to refresh user data here if it's crucial for the initial render
    // For example, if userProvider's currentUser isn't yet fully synchronized with what's
    // needed for the role check, you could do:
    // await Provider.of<UserProvider>(context, listen: false).fetchCurrentUser();
    // However, since AuthService.init() was already called in main(), currentUser
    // should be available from authService.
  }

  Future<void> _initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await Connectivity().checkConnectivity();
      _logger.d('MyApp: Initial connectivity check result: $result');
    } catch (e) {
      _logger.e('MyApp: Could not check connectivity: $e');
      result = [ConnectivityResult.none];
    }

    if (!mounted) {
      _logger.w('MyApp: _initConnectivity called but widget is not mounted.');
      return;
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    final bool hadConnection =
        !_connectionStatus.contains(ConnectivityResult.none);
    final bool hasConnectionNow = !result.contains(ConnectivityResult.none);

    setState(() {
      _connectionStatus = result;
    });

    _logger.d(
      'MyApp: Connectivity status updated. Current: $_connectionStatus',
    );

    if (!hadConnection && hasConnectionNow) {
      _logger.i(
        'MyApp: Network just became available. Attempting to re-engage services...',
      );
      if (widget.pusherService.isInitialized) {
        _logger.d(
          'MyApp: PusherService is initialized, calling resubscribeToChannels.',
        );
        widget.pusherService.resubscribeToChannels();
      } else {
        _logger.w(
          'MyApp: PusherService is not initialized after network came back. This might indicate an earlier failure.',
        );
        try {
          await widget.pusherService.initialize();
          _logger.i(
            'MyApp: PusherService successfully re-initialized after network recovery.',
          );
        } catch (e) {
          _logger.e(
            'MyApp: Failed to re-initialize PusherService on network recovery: $e',
          );
        }
      }
    } else if (hadConnection && !hasConnectionNow) {
      _logger.w('MyApp: Network just went offline.');
    }
  }

  @override
  void dispose() {
    _logger.d(
      'MyApp: Disposing of connectivity subscription and WidgetsBindingObserver.',
    );
    _connectivitySubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.d('MyApp: App lifecycle state changed to: $state');
    if (state == AppLifecycleState.resumed) {
      _logger.i('MyApp: App resumed. Re-checking connectivity.');
      _initConnectivity(); // Re-check connectivity when app resumes
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // Once initialization is complete, determine the actual home screen
          final authService = Provider.of<AuthService>(context);
          // final userProvider = Provider.of<UserProvider>(context);

          final currentUser = authService.currentUser;

          Widget homeScreen;

          if (!authService.isAuthenticated ||
              currentUser == null ||
              currentUser.uuid.isEmpty) {
            // Condition 1: User isn't authenticated, or no user data/UUID
            _logger.i(
              'MyApp: User not authenticated or missing UUID. Showing Wawu screen.',
            );
            homeScreen = const Wawu();
          } else {
            // User is authenticated and has user data with UUID
            final userRole = currentUser.role?.toUpperCase();

            if (userRole == 'SELLER' ||
                userRole == 'BUYER' ||
                userRole == 'PROFESSIONAL' ||
                userRole == 'ARTISAN') {
              // Condition 2: Authenticated, user data, UUID, and specific roles
              _logger.i(
                'MyApp: User is authenticated with role $userRole. Navigating to MainScreen.',
              );
              homeScreen = const Plan();
            } else {
              // Condition 3: Authenticated, user data, UUID, but role is not one of the specified
              // ECOMMERCE_USER.
              _logger.i(
                'MyApp: User is authenticated with role $userRole. Navigating to WawuEcommerce.',
              );
              homeScreen = const WawuMerchMain();
            }
          }

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
            home: homeScreen,
          );
        } else {
          // While initializing, show the splash screen
          return MaterialApp(
            home: SplashScreen(), // Your custom splash screen
          );
        }
      },
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
            // You can replace this with your logo or any other splash content
            Image.asset(
              'assets/logo2.png', // Replace with your actual logo path
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 300,
              child: Text(
                'Are you tired? Worn out? Burned out on getting the world to see you and pay you? Come to me. Get away with me and you’ll recover your life. I’ll show you how to take a real rest. Walk with me and work with me watch how I do it',
                style: GoogleFonts.sora(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Matthew 11:28 MSG',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
