import 'package:flutter/material.dart';
import 'package:wawu_mobile/features/authentication/screens/onboarding/widgets/onBoardingDotNavigation.dart';
import 'package:wawu_mobile/features/authentication/screens/onboarding/widgets/onboarding_next_button.dart';
import 'package:wawu_mobile/features/authentication/screens/onboarding/widgets/onboarding_page.dart';
import 'package:wawu_mobile/features/authentication/screens/onboarding/widgets/onboarding_skip.dart';
import 'package:wawu_mobile/utils/constants/text_string.dart';
import 'package:provider/provider.dart';

import '../../../../utils/constants/image_strings.dart';
import '../../controllers/onboarding_controller.dart';


class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OnBoardingProvider>(context, listen: true);

    return Scaffold(
      body: Stack(
        children: [
          // Horizontal Scrollable PageView
          PageView(
            controller: provider.pageController, // ✅ Corrected
            onPageChanged: provider.updatePageIndicator, // ✅ Pass function reference
            children: const [
              OnBoardingPage(
                image: wawuImages.onboarding1,
                title: wawuText.onBoardingTitle1,
                subtitle: wawuText.onBoardingSubTitle1,
              ),
              OnBoardingPage(
                image: wawuImages.onboarding2,
                title: wawuText.onBoardingTitle2,
                subtitle: wawuText.onBoardingSubTitle2,
              ),
              OnBoardingPage(
                image: wawuImages.onboarding3,
                title: wawuText.onBoardingTitle3,
                subtitle: wawuText.onBoardingSubTitle3,
              ),
            ],
          ),

          // Skip button
          const OnBoardingSkip(),

          // Dot Navigation (SmoothPageIndicator)
          const OnBoardingDotNavigation(),

          // Circular Next Button
          const OnBoardingNextButton(),
        ],
      ),
    );
  }
}
