import 'package:flutter/material.dart';
import '../cached_image.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class ImageTextCard extends StatelessWidget {
  final String asset;
  final String text;
  final Color? color;
  final GestureTapCallback? function;
  const ImageTextCard({
    super.key,
    required this.asset,
    required this.text,
    this.function,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: function,
      child: SizedBox(
        width: 150,
        child: Column(
          spacing: 10.0,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.fromLTRB(0, 6.0, 0, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: color ?? wawuColors.primary.withAlpha(50),
                ),
                clipBehavior: Clip.hardEdge,
                child: CachedImage(
                  urlOrAsset: asset,
                  width: 140,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Text(text, style: TextStyle(overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
