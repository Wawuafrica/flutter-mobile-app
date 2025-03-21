import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class CustomIntroText extends StatelessWidget {
  final String text;
  final bool isRightText;
  final GestureTapCallback? navFunction;
  const CustomIntroText({
    super.key,
    required this.text,
    this.isRightText = false,
    this.navFunction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        Expanded(
          child: Container(
            width: double.infinity,
            height: 1,
            color: const Color.fromARGB(255, 216, 216, 216),
          ),
        ),
        if (isRightText)
          GestureDetector(
            onTap: navFunction,
            child: Text(
              'See All',
              style: TextStyle(color: wawuColors.primary, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
