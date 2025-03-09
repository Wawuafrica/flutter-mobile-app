import 'package:flutter/material.dart';
import 'package:wawu_mobile/widgets/message_card/message_card.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            SizedBox(height: 20),
            MessageCard(),
            MessageCard(),
            MessageCard(),
            MessageCard(),
            MessageCard(),
            MessageCard(),
          ],
        ),
      ),
    );
  }
}
