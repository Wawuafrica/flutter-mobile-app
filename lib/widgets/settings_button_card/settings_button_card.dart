import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class SettingsButtonCard extends StatelessWidget {
  final String title;
  final GestureTapCallback navigate;

  const SettingsButtonCard({
    super.key,
    required this.title,
    required this.navigate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: navigate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              // color: wawuColors.primary.withAlpha(50),
              border: Border.all(width: 0.5, color: wawuColors.primary),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.all(20.0),
            child: Align(alignment: Alignment.centerLeft, child: Text(title)),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
