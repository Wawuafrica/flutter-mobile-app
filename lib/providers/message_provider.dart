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

    try {
      // Get conversation or create it if it doesn't exist
      final response = await _apiService.get<Map<String, dynamic>>(
        '/messages/conversations',
        queryParameters: {'receiver_id': otherUserId},
      );

      if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
        final conversationData = response['data'] as Map<String, dynamic>;
        final String conversationId = conversationData['uuid'] as String;
        
        // Now fetch messages for this conversation
        final messagesResponse = await _apiService.get<Map<String, dynamic>>(
          '/messages/conversations/$conversationId',
        );
        
        if (messagesResponse.containsKey('data') && messagesResponse['data'] is List) {
          final List<dynamic> messagesJson = messagesResponse['data'] as List<dynamic>;
          final List<Message> messages =
              messagesJson
                  .map((json) => Message.fromJson(json as Map<String, dynamic>))
                  .toList();

          // Sort messages by timestamp
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          _conversations[_currentConversationId!] = messages;
          
          // Mark messages as read automatically when loaded
          await markMessagesAsRead(conversationId, userId);
          
          return;
        }
      }
      
      // If no messages found, initialize with empty list
      _conversations[_currentConversationId!] = [];
      return;
    } catch (e) {
      print('Failed to load messages: $e');
      return;
    }
  }

  /// Sends a new message to another user
  Future<Message?> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    try {
      // Create the message payload
      final Map<String, dynamic> messageData = {
        'receiver_id': receiverId,
        'message': content,
      };
      
      // Add attachment if provided
      if (attachmentUrl != null) {
        messageData['attachment'] = attachmentUrl;
        if (attachmentType != null) {
          messageData['attachment_type'] = attachmentType;
        }
      }

      // Send the message
      final response = await _apiService.post<Map<String, dynamic>>(
        '/messages',
        data: messageData,
      );

      if (response.containsKey('data')) {
        final message = Message.fromJson(response['data'] as Map<String, dynamic>);

        // Add message to current conversation
        if (_currentConversationId != null) {
          final conversationId = [senderId, receiverId]..sort();
          final sentConversationId = conversationId.join('_');

          if (_currentConversationId == sentConversationId) {
            if (!_conversations.containsKey(_currentConversationId!)) {
              _conversations[_currentConversationId!] = [];
            }
            _conversations[_currentConversationId!]!.add(message);
            notifyListeners();
          }
        }

        return message;
      } else {
        print('Failed to send message: Invalid response');
        return null;
      }
    } catch (e) {
      print('Failed to send message: $e');
      return null;
    }
  }

  /// Marks messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      // Mark all messages in the conversation as read
      await _apiService.post<Map<String, dynamic>>(
        '/messages/conversations/$conversationId/read',
        data: {},
      );

      // Update local messages to show as read
      if (_conversations.containsKey(_currentConversationId!)) {
        final updatedMessages =
            _conversations[_currentConversationId!]!.map((message) {
              if (message.receiverId == userId && !message.isRead) {
                return message.copyWith(isRead: true);
              }
              return message;
            }).toList();

        _conversations[_currentConversationId!] = updatedMessages;
        notifyListeners();
      }

      return;
    } catch (e) {
      print('Failed to mark messages as read: $e');
      return;
    }
  }

  /// Subscribes to Pusher channel for real-time message updates
  Future<void> _subscribeToConversation(String conversationId) async {
    // Subscribe to the messages channel
    final channelName = 'messages';

    try {
      final channel = await _pusherService.subscribeToChannel(channelName);
      if (channel != null) {
        // Bind to new message events
        _pusherService.bindToEvent(channelName, 'MessageSent', (data) async {
          if (data is String) {
            final messageData = jsonDecode(data) as Map<String, dynamic>;
          
            // Check if this message belongs to our current conversation
            if (messageData.containsKey('message') && 
                messageData['message'] is Map<String, dynamic>) {
            
              final Map<String, dynamic> msgData = messageData['message'] as Map<String, dynamic>;
              final Message message = Message.fromJson(msgData);
            
              // Create the conversation ID to match our format
              final msgConvMembers = [message.senderId, message.receiverId]..sort();
              final msgConversationId = msgConvMembers.join('_');
            
              // Only add if it belongs to our current conversation
              if (msgConversationId == _currentConversationId) {
                if (!_conversations.containsKey(_currentConversationId)) {
                  _conversations[_currentConversationId!] = [];
                }
              
                // Add to conversation if not already there (by ID)
                if (!_conversations[_currentConversationId!]!.any((m) => m.id == message.id)) {
                  _conversations[_currentConversationId!]!.add(message);
                  notifyListeners();
                }
              }
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
    } catch (e) {
      print('Failed to subscribe to conversation: $e');
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
