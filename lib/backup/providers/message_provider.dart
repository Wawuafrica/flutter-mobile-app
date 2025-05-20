import 'dart:convert';
import '../models/message.dart';
import '../providers/base_provider.dart';
import '../services/api_service.dart';
import '../services/pusher_service.dart';

/// MessageProvider manages the state of messages between users.
///
/// This provider handles:
/// - Fetching message history between two users
/// - Sending new messages
/// - Receiving real-time message updates via Pusher
/// - Marking messages as read
class MessageProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;

  // Maps conversation IDs to messages
  final Map<String, List<Message>> _conversations = {};
  String? _currentConversationId;

  // Getters
  List<Message> get currentMessages =>
      _currentConversationId != null
          ? _conversations[_currentConversationId!] ?? []
          : [];

  String? get currentConversationId => _currentConversationId;

  MessageProvider({ApiService? apiService, PusherService? pusherService})
    : _apiService = apiService ?? ApiService(),
      _pusherService = pusherService ?? PusherService();

  /// Sets the current conversation ID and loads messages if not already loaded
  Future<void> setCurrentConversation(String userId, String otherUserId) async {
    // Create a consistent conversation ID regardless of order of user IDs
    final conversationId = [userId, otherUserId]..sort();
    final newConversationId = conversationId.join('_');

    if (_currentConversationId != newConversationId) {
      _currentConversationId = newConversationId;

      // Load messages if not already loaded
      if (!_conversations.containsKey(_currentConversationId)) {
        await loadMessages(userId, otherUserId);
      } else {
        // Just notify listeners if we already have the messages
        notifyListeners();
      }

      // Subscribe to Pusher channel for this conversation
      await _subscribeToConversation(_currentConversationId!);
    }
  }

  /// Loads message history between two users
  Future<void> loadMessages(String userId, String otherUserId) async {
    if (_currentConversationId == null) {
      final conversationId = [userId, otherUserId]..sort();
      _currentConversationId = conversationId.join('_');
    }

    await handleAsync(() async {
      // TODO: Replace with actual endpoint
      final response = await _apiService.get<Map<String, dynamic>>(
        '/messages',
        queryParameters: {'user_id': userId, 'other_user_id': otherUserId},
      );

      final List<dynamic> messagesJson = response['messages'] as List<dynamic>;
      final List<Message> messages =
          messagesJson
              .map((json) => Message.fromJson(json as Map<String, dynamic>))
              .toList();

      // Sort messages by timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      _conversations[_currentConversationId!] = messages;

      return messages;
    }, errorMessage: 'Failed to load messages');
  }

  /// Sends a new message to another user
  Future<Message?> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    return await handleAsync(() async {
      final timestamp = DateTime.now();

      // TODO: Replace with actual endpoint
      final response = await _apiService.post<Map<String, dynamic>>(
        '/messages/send',
        data: {
          'sender_id': senderId,
          'receiver_id': receiverId,
          'content': content,
          'timestamp': timestamp.toIso8601String(),
          if (attachmentUrl != null) 'attachment_url': attachmentUrl,
          if (attachmentType != null) 'attachment_type': attachmentType,
        },
      );

      final message = Message.fromJson(response);

      // Add message to current conversation
      if (_currentConversationId != null) {
        final conversationId = [senderId, receiverId]..sort();
        final sentConversationId = conversationId.join('_');

        if (_currentConversationId == sentConversationId) {
          if (!_conversations.containsKey(_currentConversationId!)) {
            _conversations[_currentConversationId!] = [];
          }
          _conversations[_currentConversationId!]!.add(message);
        }
      }

      return message;
    }, errorMessage: 'Failed to send message');
  }

  /// Marks messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    await handleAsync(() async {
      // TODO: Replace with actual endpoint
      await _apiService.put<Map<String, dynamic>>(
        '/messages/read',
        data: {'conversation_id': conversationId, 'user_id': userId},
      );

      // Update local messages to show as read
      if (_conversations.containsKey(conversationId)) {
        final updatedMessages =
            _conversations[conversationId]!.map((message) {
              if (message.receiverId == userId && !message.isRead) {
                return message.copyWith(isRead: true);
              }
              return message;
            }).toList();

        _conversations[conversationId] = updatedMessages;
      }

      return true;
    }, errorMessage: 'Failed to mark messages as read');
  }

  /// Subscribes to Pusher channel for real-time message updates
  Future<void> _subscribeToConversation(String conversationId) async {
    // Channel name pattern: 'conversation-{conversationId}'
    final channelName = 'conversation-$conversationId';

    final channel = await _pusherService.subscribeToChannel(channelName);
    if (channel != null) {
      // Bind to message events
      _pusherService.bindToEvent(channelName, 'new-message', (data) async {
        if (data is String) {
          final messageData = jsonDecode(data) as Map<String, dynamic>;
          final message = Message.fromJson(messageData);

          // Add message to conversation
          if (_conversations.containsKey(conversationId)) {
            _conversations[conversationId]!.add(message);
            notifyListeners();
          }
        }
      });

      // Bind to message read events
      _pusherService.bindToEvent(channelName, 'message-read', (data) async {
        if (data is String) {
          final readData = jsonDecode(data) as Map<String, dynamic>;
          final String messageId = readData['message_id'] as String;

          // Update message read status
          if (_conversations.containsKey(conversationId)) {
            final updatedMessages =
                _conversations[conversationId]!.map((message) {
                  if (message.id == messageId) {
                    return message.copyWith(isRead: true);
                  }
                  return message;
                }).toList();

            _conversations[conversationId] = updatedMessages;
            notifyListeners();
          }
        }
      });
    }
  }

  /// Clears all message data
  void clearAll() {
    _conversations.clear();
    _currentConversationId = null;
    resetState();
  }

  @override
  void dispose() {
    if (_currentConversationId != null) {
      _pusherService.unsubscribeFromChannel(
        'conversation-$_currentConversationId',
      );
    }
    super.dispose();
  }
}
