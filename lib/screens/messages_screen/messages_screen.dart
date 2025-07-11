import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/message_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/messages_screen/single_message_screen/single_message_screen.dart';
import 'package:wawu_mobile/widgets/message_card/message_card.dart';
import 'package:wawu_mobile/models/chat_user.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  // Store provider references safely
  MessageProvider? _messageProvider;
  UserProvider? _userProvider;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _messageProvider = Provider.of<MessageProvider>(context, listen: false);
      _userProvider = Provider.of<UserProvider>(context, listen: false);
      _refreshConversations();
    }
    _isInit = false;
  }

  @override
  void dispose() {
    // Clear provider references
    _messageProvider = null;
    _userProvider = null;
    super.dispose();
  }

  Future<void> _handleConversationTap(conversation) async {
    // Check if widget is still mounted and providers are available
    if (!mounted || _messageProvider == null || _userProvider == null) return;

    final currentUserId = _userProvider!.currentUser?.uuid ?? '';

    if (currentUserId.isEmpty) {
      _showError('User not authenticated');
      return;
    }

    try {
      // Find the other participant
      final otherParticipant = conversation.participants.firstWhere(
        (user) => user.id != currentUserId,
        orElse: () => throw Exception('No other participant found'),
      );

      // Set current conversation before navigation
      _messageProvider!.setCurrentConversation(
        currentUserId,
        otherParticipant.id,
      );

      // Check if widget is still mounted after async operation
      if (!mounted) return;

      // Navigate to SingleMessageScreen
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SingleMessageScreen()),
      );
    } catch (e) {
      print('Error opening conversation: $e');
      _showError('Failed to open conversation');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _refreshConversations() async {
    if (!mounted || _messageProvider == null) return;

    try {
      await _messageProvider!.fetchConversations();
    } catch (e) {
      print('Error refreshing conversations: $e');
      _showError('Failed to refresh conversations');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _userProvider?.currentUser?.uuid ?? '';

    return Scaffold(
      body: Consumer<MessageProvider>(
        builder: (context, messageProvider, child) {
          if (messageProvider.isLoading &&
              messageProvider.allConversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversations = messageProvider.allConversations;
          if (conversations.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshConversations,
              child: Stack(
                children: [
                  ListView(), // Needed for the indicator to work
                  const Center(child: Text('No conversations yet')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshConversations,
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];

                // Get the other participant's ID
                final otherParticipantId =
                    conversation.participants
                        .firstWhere(
                          (user) => user.id != currentUserId,
                          orElse:
                              () => ChatUser(
                                id: '',
                                name: 'Unknown',
                                avatar: null,
                              ),
                        )
                        .id;

                // Get cached profile if available
                final cachedProfile = messageProvider.getCachedUserProfile(
                  otherParticipantId,
                );

                return MessageCard(
                  conversation: conversation,
                  currentUserId: currentUserId,
                  recipient: cachedProfile,
                  onTap: () => _handleConversationTap(conversation),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
