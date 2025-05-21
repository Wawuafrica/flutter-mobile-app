import 'package:flutter/material.dart';

class CustomTextfield extends StatelessWidget {
  final String labelText;
  final String hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool labelTextStyle2;
  final bool obscureText;
  final Color borderColor;
  final double borderRadius;
  final Function(String)? onChanged;
  final TextEditingController? controller;
  final bool maxLines;
  final int maxLinesNum;

  const CustomTextfield({
    super.key,
    this.labelText = '',
    this.hintText = '',
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.borderColor = Colors.grey,
    this.borderRadius = 10.0,
    this.onChanged,
    this.controller,
    this.labelTextStyle2 = false,
    this.maxLines = false,
    this.maxLinesNum = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelTextStyle2)
          Text(
            labelText,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
          ),
        SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: obscureText,
          onChanged: onChanged,
          maxLines:
              obscureText
                  ? 1
                  : maxLines
                  ? maxLinesNum
                  : null,
          decoration: InputDecoration(
            labelText: labelTextStyle2 ? null : labelText,
            hintText: hintText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: borderColor.withOpacity(0.8),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
