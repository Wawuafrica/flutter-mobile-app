import 'package:flutter/material.dart';

class ECard extends StatelessWidget {
  const ECard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 170,
      margin: EdgeInsets.only(right: 10.0),

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
                width: 140,
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
                style: TextStyle(overflow: TextOverflow.ellipsis, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
