// messages_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/message_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/messages_screen/single_message_screen/single_message_screen.dart';
import 'package:wawu_mobile/widgets/message_card/message_card.dart';
import 'package:wawu_mobile/models/chat_user.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart'; // Import CustomSnackBar
import 'package:wawu_mobile/widgets/full_ui_error_display.dart'; // Import FullErrorDisplay
import 'package:wawu_mobile/utils/constants/colors.dart'; // Import colors for dialog

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

  // Flag to prevent showing multiple snackbars for the same error
  bool _hasShownError = false;

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

  // Function to show the support dialog (can be reused)
  void _showErrorSupportDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Contact Support',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: wawuColors.primary,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: wawuColors.buttonSecondary),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleConversationTap(conversation) async {
    // Check if widget is still mounted and providers are available
    if (!mounted || _messageProvider == null || _userProvider == null) return;

    final currentUserId = _userProvider!.currentUser?.uuid ?? '';

    if (currentUserId.isEmpty) {
      CustomSnackBar.show(
        context,
        message: 'User not authenticated. Please log in.',
        isError: true,
      );
      return;
    }

    try {
      // Find the other participant
      final otherParticipant = conversation.participants.firstWhere(
        (user) => user.id != currentUserId,
        orElse: () => throw Exception('No other participant found'),
      );

      // Set current conversation before navigation
      await _messageProvider!.setCurrentConversation(
        currentUserId,
        otherParticipant.id,
      );

      // Mark messages as read AFTER setting current conversation, but BEFORE navigation
      // This ensures the messages in the provider are updated before SingleMessageScreen consumes them.
      _messageProvider!.markMessagesAsRead(conversation.id, currentUserId);

      // Check if widget is still mounted after async operation
      if (!mounted) return;

      // Navigate to SingleMessageScreen
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SingleMessageScreen()),
      );
    } catch (e) {
      print('Error opening conversation: $e');
      CustomSnackBar.show(
        context,
        message: 'Failed to open conversation. Please try again.',
        isError: true,
      );
      _messageProvider?.clearError(); // Clear error state in provider
    }
  }

  Future<void> _refreshConversations() async {
    if (!mounted || _messageProvider == null) return;

    try {
      await _messageProvider!.fetchConversations();
    } catch (e) {
      print('Error refreshing conversations: $e');
      CustomSnackBar.show(
        context,
        message: 'Failed to refresh conversations. Please try again.',
        isError: true,
      );
      _messageProvider?.clearError(); // Clear error state in provider
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _userProvider?.currentUser?.uuid ?? '';

    return Scaffold(
      body: Consumer<MessageProvider>(
        builder: (context, messageProvider, child) {
          // Listen for errors from MessageProvider and display SnackBar
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (messageProvider.hasError &&
                messageProvider.errorMessage != null &&
                !_hasShownError) {
              CustomSnackBar.show(
                context,
                message: messageProvider.errorMessage!,
                isError: true,
                actionLabel: 'RETRY',
                onActionPressed: () {
                  messageProvider.fetchConversations();
                },
              );
              _hasShownError = true;
              messageProvider.clearError(); // Clear error state
            } else if (!messageProvider.hasError && _hasShownError) {
              _hasShownError = false;
            }
          });

          // Show loading indicator if loading and no conversations are loaded yet
          if (messageProvider.isLoading &&
              messageProvider.allConversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show full error display if there's an error and no conversations are loaded
          if (messageProvider.hasError &&
              messageProvider.allConversations.isEmpty &&
              !messageProvider.isLoading) {
            return FullErrorDisplay(
              errorMessage:
                  messageProvider.errorMessage ??
                  'Failed to load conversations. Please try again.',
              onRetry: () {
                messageProvider.fetchConversations();
              },
              onContactSupport: () {
                _showErrorSupportDialog(
                  context,
                  'If this problem persists, please contact our support team. We are here to help!',
                );
              },
            );
          }

          final conversations = messageProvider.allConversations;

          // Show "No conversations yet" if list is empty after loading/error check
          if (conversations.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshConversations,
              child: Stack(
                children: [
                  ListView(), // Needed for the indicator to work
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a new chat to see it here.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                final otherParticipant = conversation.participants.firstWhere(
                  (user) => user.id != currentUserId,
                  orElse: () => ChatUser(id: '', name: 'Unknown', avatar: null),
                );

                // Get cached profile if available
                final cachedProfile = messageProvider.getCachedUserProfile(
                  otherParticipant.id,
                );

                // Calculate unread messages for this conversation
                final unreadCount =
                    conversation.messages
                        .where(
                          (message) =>
                              message.senderId == otherParticipant.id &&
                              !message.isRead,
                        )
                        .length;

                return MessageCard(
                  conversation: conversation,
                  currentUserId: currentUserId,
                  recipient: cachedProfile,
                  unreadCount: unreadCount, // Pass unread count to MessageCard
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
