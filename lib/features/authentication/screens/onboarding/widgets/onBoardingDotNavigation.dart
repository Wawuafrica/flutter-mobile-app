import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/device/device_utility.dart';
import '../../../controllers/onboarding_controller.dart';



class OnBoardingDotNavigation extends StatelessWidget {
  const OnBoardingDotNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OnBoardingProvider>(context, listen: false);

    return Positioned(
      bottom: wawuDeviceUtils.getBottomNavigationHeight() * 25,
      left: wawuSizes.defaultSpace,
      child: SmoothPageIndicator(
        controller: provider.pageController, // ✅ Use the provider’s controller
        onDotClicked: (index){
          provider.dotNavigationClick(index);
        },
        count: 3,
        effect: const ExpandingDotsEffect(
          activeDotColor: wawuColors.primary, // Change based on your theme
          dotHeight: 6,
        ),
      ),
    );
  }
}
