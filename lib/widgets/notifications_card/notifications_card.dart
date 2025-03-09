import 'package:flutter/material.dart';

class NotificationsCard extends StatelessWidget {
  const NotificationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color.fromARGB(255, 224, 224, 224),
              width: 0.5,
            ),
          ),
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Message',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '2 mins ago',
                    style: TextStyle(fontWeight: FontWeight.w300, fontSize: 11),
                  ),
                ],
              ),
              Text(
                'Lorem ipsum dolor sit amet, consectetur adipisaliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco...',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
