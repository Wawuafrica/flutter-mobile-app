import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class Customcheckmark extends StatefulWidget {
  const Customcheckmark({super.key});

  @override
  State<Customcheckmark> createState() => _CustomcheckmarkState();
}

class _CustomcheckmarkState extends State<Customcheckmark> {
  bool isClicked = false;

  void _toggleCheckbox() {
    setState(() {
      isClicked = !isClicked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCheckbox,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color:
              isClicked ? wawuColors.primary : wawuColors.primary.withAlpha(30),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}
