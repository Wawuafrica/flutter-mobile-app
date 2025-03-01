import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/device/device_utility.dart';

import '../../../controllers/onboarding_controller.dart';

class OnBoardingSkip extends StatelessWidget {
  const OnBoardingSkip({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OnBoardingProvider>(context, listen: false); // ✅ Fix: Define provider

    return Positioned(
      top: wawuDeviceUtils.getAppBarHeight(),
      right: wawuSizes.defaultSpace,
      child: TextButton(
        onPressed: () => provider.skipPage(context), // ✅ Now correctly calls skipPage()
        child: const Text("Skip"),
      ),
    );
  }
}
