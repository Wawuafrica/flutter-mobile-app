import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/utils/theme/theme.dart';


import 'app.dart';
import 'features/authentication/controllers/onboarding_controller.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnBoardingProvider()), // ✅ Provide onboarding state
      ],
      child: const App(),
    ),
  );
}

