import 'package:flutter/material.dart';

class CustomRowSingleColumn extends StatelessWidget {
  final String leftText;
  final TextStyle leftTextStyle;
  final String rightText;
  final TextStyle rightTextStyle;
  const CustomRowSingleColumn({
    super.key,
    required this.leftText,
    required this.leftTextStyle,
    required this.rightText,
    required this.rightTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(leftText, style: leftTextStyle)),
        Expanded(
          child: Text(
            rightText,
            style: rightTextStyle,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
