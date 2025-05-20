import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/wawu/wawu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

// Services
import 'services/api_service.dart';
import 'services/pusher_service.dart';
import 'services/auth_service.dart';

// Providers
import 'providers/user_provider.dart';
import 'providers/message_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/gig_provider.dart';
import 'providers/application_provider.dart';
import 'providers/review_provider.dart';
import 'providers/blog_provider.dart';
import 'providers/product_provider.dart';
import 'providers/category_provider.dart';
import 'providers/plan_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = Logger();

  try {
    final apiService = ApiService();
    final authService = AuthService(apiService: apiService, logger: logger);
    await apiService.initialize(
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://staging.wawuafrica.com/api',
      ),
      authService: authService,
    );

    final pusherService = PusherService();

    runApp(
      MultiProvider(
        providers: [
          Provider<Logger>.value(value: logger),
          Provider<ApiService>.value(value: apiService),
          Provider<PusherService>.value(value: pusherService),
          Provider<AuthService>.value(value: authService),

          ChangeNotifierProvider(
            create:
                (context) => UserProvider(
                  authService: authService,
                  apiService: apiService,
                  pusherService: pusherService,
                  logger: logger,
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
            create:
                (context) =>
                    CategoryProvider(apiService: apiService, logger: logger),
          ),
          ChangeNotifierProvider(
            create:
                (context) =>
                    PlanProvider(apiService: apiService, logger: logger),
          ),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    logger.e('Error initializing app: $e\n$stackTrace');
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Wawu(),
    );
  }
}
