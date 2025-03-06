import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class UploadImage extends StatelessWidget {
  const UploadImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: wawuColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(20.0),
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -8,
              right: -108,
              child: Icon(Icons.delete, size: 20),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_rounded, size: 50),
                SizedBox(height: 10),
                Text('Upload Image'),
                Text('500kb'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
