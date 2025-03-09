import 'package:flutter/material.dart';
import 'package:wawu_mobile/widgets/notifications_card/notifications_card.dart';

class Notifications extends StatelessWidget {
  const Notifications({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            SizedBox(height: 10),
            NotificationsCard(),
            NotificationsCard(),
            NotificationsCard(),
            NotificationsCard(),
            NotificationsCard(),
            NotificationsCard(),
            NotificationsCard(),
            NotificationsCard(),
            NotificationsCard(),
            NotificationsCard(),
          ],
        ),
      ),
    );
  }
}
