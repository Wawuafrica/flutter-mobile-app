import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/conversation.dart';
import 'package:wawu_mobile/providers/message_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/message_card/message_card.dart';

class MessagesScreen extends StatelessWidget {
  MessagesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<UserProvider>(context).currentUser?.uuid ?? '';

    return Scaffold(
      backgroundColor: wawuColors.white,
      appBar: AppBar(
        elevation: 1.0,
        title: const Text(
          'Messages',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10.0),
            width: 40,
            height: 40,
            child: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navigate to a screen to start a new conversation
                // Example: Navigator.pushNamed(context, '/select_recipient');
              },
            ),
          ),
        ],
      ),
      body: currentUserId.isEmpty
          ? const Center(child: Text('Please log in to view messages'))
          : Consumer<MessageProvider>(
              builder: (context, messageProvider, child) {
                if (messageProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final conversations = messageProvider.allConversations;

                return conversations.isEmpty
                    ? const Center(child: Text('No conversations found'))
                    : ListView.builder(
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = conversations[index];
                          return MessageCard(
                            conversation: conversation,
                            currentUserId: currentUserId,
                            onTap: () {
                              Provider.of<MessageProvider>(context, listen: false)
                                  .setCurrentConversation(
                                      currentUserId,
                                      conversation.participants
                                          .firstWhere((user) => user.id != currentUserId)
                                          .id);
                              Navigator.pushNamed(context, '/single_message');
                            },
                          );
                        },
                      );
              },
            ),
    );
  }
}