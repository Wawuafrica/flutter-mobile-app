import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class MessageBubbles extends StatelessWidget {
  final bool isLeft;
  final String message;
  final String time;

  const MessageBubbles({
    super.key,
    this.isLeft = true,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color:
                isLeft ? wawuColors.primary.withAlpha(30) : wawuColors.primary,
            borderRadius:
                isLeft
                    ? BorderRadius.only(
                      topRight: Radius.circular(15),
                      topLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    )
                    : BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
          ),
          child: Column(
            crossAxisAlignment:
                isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: isLeft ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
        ),
        Text(time, style: TextStyle(fontSize: 10, color: Colors.grey)),
        SizedBox(height: 10),
      ],
    );
  }
}
