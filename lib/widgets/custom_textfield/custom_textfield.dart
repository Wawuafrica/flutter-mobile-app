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
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Function()? onTap; // <--- ADDED: Callback for tap events
  final bool readOnly; // <--- ADDED: To make the text field read-only

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
    this.validator,
    this.keyboardType,
    this.onTap, // <--- ADDED to constructor
    this.readOnly = false, // <--- ADDED to constructor with a default value
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
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          onChanged: onChanged,
          maxLines:
              obscureText // Ensure maxLines is 1 for obscureText to prevent multi-line passwords
                  ? 1
                  : maxLines
                      ? maxLinesNum
                      : null,
          keyboardType: keyboardType,
          validator: validator,
          onTap: onTap, // <--- PASSED TO TextFormField
          readOnly: readOnly, // <--- PASSED TO TextFormField
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: Colors.red, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: Colors.red, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}