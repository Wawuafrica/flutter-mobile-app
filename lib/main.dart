import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/ad_provider.dart';
import 'package:wawu_mobile/screens/wawu/wawu.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async'; // Import for StreamSubscription
import 'package:logger/logger.dart'; // Import Logger
import 'package:wawu_mobile/utils/constants/colors.dart';

// Services
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/pusher_service.dart';

// Providers
import 'providers/application_provider.dart';
import 'providers/blog_provider.dart';
import 'providers/category_provider.dart';
import 'providers/gig_provider.dart';
import 'providers/message_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/product_provider.dart';
import 'providers/review_provider.dart';
import 'providers/user_provider.dart';

// Initialize Logger
final _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0, // No method calls to be displayed
    errorMethodCount: 8, // Number of method calls if stacktrace is provided
    lineLength: 120, // Width of the output
    colors: true, // Colorful log messages
    printEmojis: true, // Print an emoji for each log message
    printTime: false, // Should each log message contain a timestamp
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
            create: (context) => AdProvider(apiService: apiService),
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
          ChangeNotifierProvider(
            create:
                (context) => ApplicationProvider(
                  apiService: apiService,
                  pusherService: pusherService,
                ),
          ),
          ChangeNotifierProvider(
            create:
                (context) => ReviewProvider(
                  apiService: apiService,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _logger.d('MyApp: Initializing connectivity monitoring...');
    _initConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
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
      // PusherService is designed to auto-reconnect and re-subscribe on connection state change.
      // So, directly calling resubscribeToChannels is usually sufficient here.
      // The `initialize` call is intentionally removed as it implies a full re-setup.
      if (widget.pusherService.isInitialized) {
        _logger.d(
          'MyApp: PusherService is initialized, calling resubscribeToChannels.',
        );
        widget.pusherService.resubscribeToChannels();
      } else {
        _logger.w(
          'MyApp: PusherService is not initialized after network came back. This might indicate an earlier failure.',
        );
        // Consider re-initializing PusherService here if it failed initially.
        // However, the current setup assumes main.dart handles initial setup.
        // For robustness, you might want to add a retry mechanism for Pusher.
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
      // You might want to add specific handling here, e.g., display a message
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
      home: const Wawu(),
    );
  }
}
