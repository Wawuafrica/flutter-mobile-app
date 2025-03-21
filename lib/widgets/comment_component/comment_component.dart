import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class CommentComponent extends StatelessWidget {
  const CommentComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15.0),
      // color: Colors.white,
      child: Row(
        spacing: 10.0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: wawuColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              spacing: 10.0,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'John Doe',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text('2hrs Ago', style: TextStyle(fontSize: 11)),
                  ],
                ),
                Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore ma.',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
