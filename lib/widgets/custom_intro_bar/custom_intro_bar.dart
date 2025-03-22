import 'package:flutter/material.dart';

class CustomIntroBar extends StatefulWidget {
  final String text;
  final String desc;
  final bool topPadding;
  const CustomIntroBar({
    super.key,
    required this.text,
    required this.desc,
    this.topPadding = true,
  });

  @override
  State<CustomIntroBar> createState() => _CustomIntroBarState();
}

class _CustomIntroBarState extends State<CustomIntroBar> {
  String? selectedValue;
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
        Text(
          widget.desc,
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
        ),
        SizedBox(height: 30),
      ],
    );
  }
}
