import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/wawu_ecommerce_screen/single_package/single_package.dart';

class ECard extends StatelessWidget {
  final bool isMargin;
  const ECard({super.key, this.isMargin = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SinglePackage()),
        );
      },
      child: Container(
        width: isMargin ? 140 : double.infinity,
        height: 170,
        margin: EdgeInsets.only(right: isMargin ? 10.0 : 0.0),

        child: Column(
          spacing: 5.0,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  height: 160,
                  width: isMargin ? 140 : double.infinity,
                  'assets/images/section/video.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Column(
              spacing: 10.0,
              children: [
                Row(
                  spacing: 10.0,
                  children: [
                    Text(
                      '\$450',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$500',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Autumn And Winter Casual cotton-padded jacket',
                  maxLines: 2,
                  style: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
