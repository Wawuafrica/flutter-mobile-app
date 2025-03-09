import 'package:flutter/material.dart';

class ImageTextCard extends StatelessWidget {
  final String asset;
  final String text;
  const ImageTextCard({super.key, required this.asset, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      child: Column(
        spacing: 10.0,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.asset(asset, width: 140, fit: BoxFit.cover),
            ),
          ),
          Text(text, style: TextStyle(overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
