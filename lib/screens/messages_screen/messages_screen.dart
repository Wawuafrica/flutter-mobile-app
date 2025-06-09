import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/message_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/messages_screen/single_message_screen/single_message_screen.dart';
import 'package:wawu_mobile/widgets/message_card/message_card.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final messageProvider = Provider.of<MessageProvider>(
          context,
          listen: false,
        );
        messageProvider.fetchConversations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Provider.of<UserProvider>(context).currentUser?.uuid ?? '';

    return Scaffold(
      body:
          currentUserId.isEmpty
              ? const Center(child: Text('Please log in to view messages'))
              : Consumer<MessageProvider>(
                builder: (context, messageProvider, child) {
                  if (messageProvider.isLoading &&
                      messageProvider.allConversations.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (messageProvider.hasError &&
                      messageProvider.allConversations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${messageProvider.errorMessage}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed:
                                () => messageProvider.fetchConversations(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
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
                            onTap: () async {
                              // Check if widget is still mounted before navigation
                              if (!mounted) return;

                              try {
                                // Find the other participant
                                final otherParticipant = conversation
                                    .participants
                                    .firstWhere(
                                      (user) => user.id != currentUserId,
                                      orElse:
                                          () =>
                                              throw Exception(
                                                'No other participant found',
                                              ),
                                    );

                                // Set current conversation before navigation
                                await Provider.of<MessageProvider>(
                                  context,
                                  listen: false,
                                ).setCurrentConversation(
                                  currentUserId,
                                  otherParticipant.id,
                                );

                                // Check if widget is still mounted after async operation
                                if (!mounted) return;

                                // Navigate to SingleMessageScreen
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const SingleMessageScreen(),
                                  ),
                                );
                              } catch (e) {
                                // Handle errors gracefully
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error opening conversation: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        },
                      );
                },
              ),
    );
  }
}
