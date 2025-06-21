import 'package:flutter/material.dart';
import 'package:wawu_mobile/services/onboarding_state_service.dart';
import 'package:wawu_mobile/screens/wawu_africa/sign_up/otp_screen.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/services/auth_service.dart';
import 'package:wawu_mobile/screens/wawu_africa/sign_up/sign_up.dart';

/// Gatekeeper for onboarding flow. Decides where to send the user based on onboarding state.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  Future<Widget> _decideScreen() async {
    final isComplete = await OnboardingStateService.isComplete();
    if (isComplete) {
      // Onboarding is done, don't show this gate (should never be routed here)
      return const SizedBox.shrink();
    }
    final step = await OnboardingStateService.getStep();
    if (step == null) {
      // User hasn't started onboarding (hasn't clicked Sign Up yet)
      return const SignUp();
    }
    // You can add more steps here if onboarding is multi-step
    if (step == 'otp') {
      // Try to get AuthService and email from context or storage.
      final authService = Provider.of<AuthService>(context, listen: false);
      // You may want to persist the email in onboarding state as well for a more robust solution.
      // For now, fallback to empty string if not available.
      String email = '';
      // Optionally, retrieve email from shared prefs or userProvider if you save it there.
      return OtpScreen(authService: authService, email: email);
    }
    // Default fallback: show sign up
    return const SignUp();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _decideScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return snapshot.data!;
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
