import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/features/authentication/screens/onboarding/onboarding.dart';
import 'package:wawu_mobile/utils/theme/theme.dart';

import 'features/authentication/controllers/onboarding_controller.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnBoardingProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: "/",
          routes: {
            "/login": (context) => const LoginScreen(),
          },
          themeMode: ThemeMode.light,
          theme: wawuTheme.lightTheme,
          // ✅ Show onboarding only if user hasn't seen it
          home: provider.hasSeenOnboarding ? const LoginScreen() : const OnBoardingScreen(),
        );
      },
    );
  }
}
