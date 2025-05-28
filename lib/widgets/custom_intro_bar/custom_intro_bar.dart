import 'package:flutter/material.dart';

class CustomIntroBar extends StatefulWidget {
  final String text;
  final String? desc; // Keep it nullable if you intend for it to be optionally null
  final bool topPadding;

  const CustomIntroBar({
    super.key,
    required this.text,
    this.desc, // Remove the default '' here if you want null to be a possibility
    this.topPadding = true,
  });

  @override
  State<CustomIntroBar> createState() => _CustomIntroBarState();
}

class _CustomIntroBarState extends State<CustomIntroBar> {
  // selectedValue seems unused in this specific widget, consider removing if not needed.
  // String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: widget.topPadding ? 20 : 0),
        Text(
          widget.text,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 23,
          ),
        ),
        SizedBox(height: 10),
        // Safely check if desc is not null and not empty before displaying
        if (widget.desc != null && widget.desc!.isNotEmpty)
          Text(
            widget.desc!, // It's safe to use ! here because of the null check above
            style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
          ),
        SizedBox(height: 30),
      ],
    );
  }
}