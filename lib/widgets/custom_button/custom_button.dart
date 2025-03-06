import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final double width;
  final double height;
  final Widget widget;
  final Color color;
  final Color textColor;
  final Border? border;
  final GestureTapCallback? function;

  const CustomButton({
    super.key,
    this.width = double.infinity,
    this.height = 50,
    required this.widget,
    required this.color,
    this.textColor = Colors.white,
    this.border,
    this.function,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: function,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: border,
        ),
        child: Center(child: widget),
      ),
    );
  }
}
