import 'package:flutter/material.dart';

class CustomIntroText extends StatelessWidget {
  final String text;
  const CustomIntroText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        SizedBox(width: 10),
        Expanded(
          child: Container(
            width: double.infinity,
            height: 1,
            color: const Color.fromARGB(255, 216, 216, 216),
          ),
        ),
      ],
    );
  }
}
