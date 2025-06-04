import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class Customcheckmark extends StatefulWidget {
  final bool isChecked;
  final ValueChanged<bool>? onChanged;

  const Customcheckmark({
    super.key,
    required this.isChecked,
    this.onChanged,
  });

  @override
  State<Customcheckmark> createState() => _CustomcheckmarkState();
}

class _CustomcheckmarkState extends State<Customcheckmark> {
  late bool isClicked;

  @override
  void initState() {
    super.initState();
    isClicked = widget.isChecked;
  }

  @override
  void didUpdateWidget(Customcheckmark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isChecked != oldWidget.isChecked) {
      setState(() {
        isClicked = widget.isChecked;
      });
    }
  }

  void _toggleCheckbox() {
    setState(() {
      isClicked = !isClicked;
    });
    if (widget.onChanged != null) {
      widget.onChanged!(isClicked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCheckbox,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isClicked ? wawuColors.primary : wawuColors.primary.withAlpha(30),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}