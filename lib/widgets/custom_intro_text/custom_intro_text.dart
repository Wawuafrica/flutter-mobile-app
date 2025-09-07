import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class CustomIntroText extends StatelessWidget {
  final String text;
  final bool isRightText;
  final GestureTapCallback? navFunction;
  final Color? color;
  const CustomIntroText({
    super.key,
    required this.text,
    this.isRightText = false,
    this.navFunction,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.w600)),
        Expanded(
          child: Container(
            width: double.infinity,
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
