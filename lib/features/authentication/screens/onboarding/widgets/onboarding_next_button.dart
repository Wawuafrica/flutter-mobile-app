import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/device/device_utility.dart';
import '../../../controllers/onboarding_controller.dart';


class OnBoardingNextButton extends StatelessWidget {
  const OnBoardingNextButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OnBoardingProvider>(context, listen: false); // ✅ Fix: Define provider

    return Positioned(
        right: wawuSizes.defaultSpace,
        bottom: wawuDeviceUtils.getBottomNavigationHeight(),
        child: ElevatedButton(
          onPressed: () => provider.nextPage(context),
          style: ElevatedButton.styleFrom(shape: CircleBorder(), backgroundColor: wawuColors.primary),
          child: Icon(Icons.arrow_right),
        )
    );
  }
}