import 'package:flutter/material.dart';
import 'onboarding_progress_indicator.dart';

/// Universal onboarding scaffold that shows the progress indicator and screen content.
class OnboardingStepScaffold extends StatelessWidget {
  final String currentStep;
  final Widget child;
  final PreferredSizeWidget? appBar;
  final EdgeInsetsGeometry? padding;
  final bool showAppBar;

  static const List<String> steps = [
    'account_type',
    'category_selection',
    'subcategory_selection',
    'plan',
    'payment',
    'payment_processing',
    'update_profile',
    'profile_update',
    'verify_payment',
    'disclaimer',
  ];

  static const Map<String, String> stepLabels = {
    'account_type': 'Account',
    'category_selection': 'Category',
    'subcategory_selection': 'Subcategory',
    'plan': 'Plan',
    'payment': 'Payment',
    'payment_processing': 'Processing',
    'update_profile': 'Intro',
    'profile_update': 'Profile',
    'verify_payment': 'Verify',
    'disclaimer': 'Disclaimer',
  };

  const OnboardingStepScaffold({
    Key? key,
    required this.currentStep,
    required this.child,
    this.appBar,
    this.padding,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? appBar : null,
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: OnboardingProgressIndicator(
                currentStep: currentStep,
                steps: steps,
                stepLabels: stepLabels,
              ),
            ),
            Expanded(
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
