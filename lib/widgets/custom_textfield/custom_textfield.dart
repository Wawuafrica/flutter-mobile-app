import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextfield extends StatefulWidget {
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
  final Function()? onTap;
  final bool readOnly;
  final List<TextInputFormatter> inputFormatters;

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
    this.onTap,
    this.readOnly = false,
    this.inputFormatters = const [],
  });

  @override
  State<CustomTextfield> createState() => _CustomTextfieldState();
}

class _CustomTextfieldState extends State<CustomTextfield> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant CustomTextfield oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update obscured state if parent's obscureText changes
    if (widget.obscureText != oldWidget.obscureText) {
      _isObscured = widget.obscureText;
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  Widget? _buildSuffixIcon() {
    // If obscureText is true, show the eye toggle icon
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _isObscured ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey[600],
        ),
        onPressed: _togglePasswordVisibility,
        splashRadius: 20, // Smaller splash radius for better UX
      );
    }

    // If obscureText is false but suffixIcon is provided, show the custom suffixIcon
    if (widget.suffixIcon != null) {
      return Icon(widget.suffixIcon);
    }

    // No suffix icon
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelTextStyle2)
          Text(
            widget.labelText,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
          ),
        const SizedBox(height: 10),
        TextFormField(
          controller: widget.controller,
          obscureText:
              _isObscured, // Use internal state instead of widget.obscureText
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          maxLines:
              _isObscured // Use internal state for maxLines logic
                  ? 1
                  : widget.maxLines
                  ? widget.maxLinesNum
                  : null,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onTap: widget.onTap,
          readOnly: widget.readOnly,
          decoration: InputDecoration(
            labelText: widget.labelTextStyle2 ? null : widget.labelText,
            hintText: widget.hintText,
            prefixIcon:
                widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
            suffixIcon: _buildSuffixIcon(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(color: widget.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(color: widget.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: widget.borderColor.withValues(alpha: 0.8),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: const BorderSide(color: Colors.red, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}
