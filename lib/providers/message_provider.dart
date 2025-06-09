import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wawu_mobile/models/chat_user.dart';
import 'package:wawu_mobile/models/conversation.dart';
import 'package:wawu_mobile/models/message.dart';
import 'package:wawu_mobile/services/api_service.dart';
import 'package:wawu_mobile/services/pusher_service.dart';
import 'package:logger/logger.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class MessageProvider extends ChangeNotifier {
  final ApiService _apiService;
  final PusherService _pusherService;
  final Logger _logger = Logger();

  List<Conversation> _allConversations = [];
  List<Message> _currentMessages = [];
  String _currentConversationId = '';
  String _currentRecipientId = '';
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  final Set<String> _subscribedChatChannels =
      {}; // Track subscribed chat channels

  MessageProvider({
    required ApiService apiService,
    required PusherService pusherService,
  }) : _apiService = apiService,
       _pusherService = pusherService;

  List<Conversation> get allConversations => _allConversations;
  List<Message> get currentMessages => _currentMessages;
  String get currentConversationId => _currentConversationId;
  String get currentRecipientId => _currentRecipientId;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  void setLoading() {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    _isLoading = false;
    _hasError = true;
    _errorMessage = message;
    _logger.e('MessageProvider Error: $message');
    notifyListeners();
  }

  void setSuccess() {
    _isLoading = false;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchConversations() async {
    setLoading();
    try {
      final response = await _apiService.get(
        '/chats',
        options: Options(headers: {'Api-Token': '{{api_token}}'}),
      );
      if (response['statusCode'] == 200 && response.containsKey('data')) {
        _allConversations =
            (response['data'] as List<dynamic>)
                .map(
                  (json) => Conversation.fromJson(json as Map<String, dynamic>),
                )
                .toList();

        // Subscribe to all conversation channels
        for (final conversation in _allConversations) {
          await _subscribeToMessages(conversation.id);
        }

        setSuccess();
        _logger.i(
          'MessageProvider: Fetched ${_allConversations.length} conversations',
        );
      } else {
        setError(response['message'] ?? 'Failed to fetch conversations');
      }
    } catch (e) {
      setError('Error fetching conversations: $e');
    }
  }

  Future<void> startConversation(
    String currentUserId,
    String recipientId, [
    String? initialMessage,
  ]) async {
    setLoading();
    try {
      // Check for existing conversation
      final existingConversation = _allConversations.firstWhere(
        (conv) =>
            conv.participants.any((user) => user.id == currentUserId) &&
            conv.participants.any((user) => user.id == recipientId),
        orElse: () => Conversation(id: '', participants: [], messages: []),
      );

      if (existingConversation.id.isNotEmpty) {
        _currentConversationId = existingConversation.id;
        _currentRecipientId = recipientId;
        await _fetchMessages(existingConversation.id);
        await _subscribeToMessages(existingConversation.id);

        if (initialMessage != null && initialMessage.isNotEmpty) {
          await sendMessage(
            senderId: currentUserId,
            receiverId: recipientId,
            content: initialMessage,
          );
        }
        setSuccess();
        return;
      }

      // Create new conversation
      final response = await _apiService.post(
        '/chats',
        data: {'user_id': recipientId},
        options: Options(headers: {'Api-Token': '{{api_token}}'}),
      );

      _logger.d('MessageProvider: Start conversation response: $response');

      if (response['statusCode'] == 200 && response.containsKey('data')) {
        _logger.d('MessageProvider: RecipientID CHECK $recipientId');
        _logger.d(
          'MessageProvider: Response data structure: ${response['data']}',
        );

        try {
          final newConversation = Conversation.fromJson(
            response['data'] as Map<String, dynamic>,
          );

          _allConversations.add(newConversation);
          _currentConversationId = newConversation.id;
          _currentRecipientId = recipientId;
          _logger.d(
            'MessageProvider: RecipientID CHECK1_5 $_currentRecipientId',
          );

          _currentMessages = [];

          // Subscribe to the new conversation channel
          await _subscribeToMessages(newConversation.id);

          if (initialMessage != null && initialMessage.isNotEmpty) {
            await sendMessage(
              senderId: currentUserId,
              receiverId: recipientId,
              content: initialMessage,
            );
          } else {
            await _fetchMessages(newConversation.id);
          }

          setSuccess();
          notifyListeners();
        } catch (jsonError) {
          _logger.e('MessageProvider: JSON parsing error: $jsonError');
          _logger.e('MessageProvider: Raw response data: ${response['data']}');
          setError('Failed to parse conversation data: $jsonError');
          return;
        }
      } else {
        setError(response['message'] ?? 'Failed to create conversation');
      }
    } catch (e) {
      _logger.e('MessageProvider: Full error details: $e');
      setError('Error starting conversation: $e');
    }
  }

  Future<void> _fetchMessages(String conversationId) async {
    setLoading();
    try {
      final response = await _apiService.get(
        '/chats/$conversationId/messages',
        options: Options(headers: {'Api-Token': '{{api_token}}'}),
      );
      if (response['statusCode'] == 200 && response.containsKey('data')) {
        _currentMessages =
            (response['data'] as List<dynamic>)
                .map((json) => Message.fromJson(json as Map<String, dynamic>))
                .toList();
        setSuccess();
        _logger.i(
          'MessageProvider: Fetched ${_currentMessages.length} messages for conversation $conversationId',
        );
      } else {
        setError(response['message'] ?? 'Failed to fetch messages');
      }
    } catch (e) {
      setError('Error fetching messages: $e');
    }
  }

  Future<Message?> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? mediaFilePath,
    String? mediaType,
  }) async {
    setLoading();
    try {
      final conversation = _allConversations.firstWhere(
        (conv) =>
            conv.participants.any((user) => user.id == senderId) &&
            conv.participants.any((user) => user.id == receiverId),
        orElse: () => Conversation(id: '', participants: [], messages: []),
      );

      String targetConversationId =
          conversation.id.isNotEmpty ? conversation.id : _currentConversationId;

      if (targetConversationId.isEmpty) {
        // Create new conversation
        final response = await _apiService.post(
          '/chats',
          data: {
            'participant_ids': [senderId, receiverId],
          },
          options: Options(headers: {'Api-Token': '{{api_token}}'}),
        );

        if (response['statusCode'] == 200 && response.containsKey('data')) {
          final newConversation = Conversation.fromJson(
            response['data'] as Map<String, dynamic>,
          );
          _allConversations.add(newConversation);
          targetConversationId = newConversation.id;
          _currentConversationId = newConversation.id;
          _currentRecipientId = receiverId;

          // Subscribe to the new conversation channel
          await _subscribeToMessages(newConversation.id);
          notifyListeners();
        } else {
          setError(response['message'] ?? 'Failed to create conversation');
          return null;
        }
      }

      final formData = FormData.fromMap({
        'message': content,
        if (mediaFilePath != null)
          'media': await MultipartFile.fromFile(mediaFilePath),
      });

      final response = await _apiService.post(
        '/chats/$targetConversationId/messages',
        data: formData,
        options: Options(headers: {'Api-Token': '{{api_token}}'}),
      );

      if (response['statusCode'] == 200 && response.containsKey('data')) {
        final newMessage = Message.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        _currentMessages.add(newMessage);

        // Update conversation in allConversations
        final convIndex = _allConversations.indexWhere(
          (conv) => conv.id == targetConversationId,
        );
        if (convIndex != -1) {
          final updatedMessages = [
            newMessage,
            ..._allConversations[convIndex].messages,
          ];
          _allConversations[convIndex] = Conversation(
            id: _allConversations[convIndex].id,
            participants: _allConversations[convIndex].participants,
            messages: updatedMessages,
          );
        } else {
          _allConversations.add(
            Conversation(
              id: targetConversationId,
              participants: [
                ChatUser(id: senderId, name: '', avatar: null),
                ChatUser(id: receiverId, name: '', avatar: null),
              ],
              messages: [newMessage],
            ),
          );
        }

        setSuccess();
        notifyListeners();
        _logger.i(
          'MessageProvider: Message sent successfully to conversation $targetConversationId',
        );
        return newMessage;
      } else {
        setError(response['message'] ?? 'Failed to send message');
        return null;
      }
    } catch (e) {
      setError('Error sending message: $e');
      return null;
    }
  }

  // Add this method to your MessageProvider class to prevent duplicate subscriptions

  Future<void> _subscribeToMessages(String conversationId) async {
    if (!_pusherService.isInitialized) {
      _logger.w(
        'MessageProvider: PusherService not initialized, cannot subscribe to messages',
      );
      return;
    }

    final channelName = 'chat.$conversationId';

    // Check if already subscribed to avoid duplicate subscriptions
    if (_subscribedChatChannels.contains(channelName)) {
      _logger.d('MessageProvider: Already subscribed to channel: $channelName');
      return;
    }

    try {
      final success = await _pusherService.subscribeToChannel(channelName);
      if (success) {
        _subscribedChatChannels.add(channelName);

        // Bind to message events
        _pusherService.bindToEvent(channelName, 'message.sent', (
          PusherEvent event,
        ) {
          _handleMessageSentEvent(event, conversationId);
        });

        // Bind to other message-related events if needed
        _pusherService.bindToEvent(channelName, 'message.read', (
          PusherEvent event,
        ) {
          _handleMessageReadEvent(event, conversationId);
        });

        _pusherService.bindToEvent(channelName, 'message.deleted', (
          PusherEvent event,
        ) {
          _handleMessageDeletedEvent(event, conversationId);
        });

        _logger.i(
          'MessageProvider: Successfully subscribed to chat channel: $channelName',
        );
      } else {
        _logger.e(
          'MessageProvider: Failed to subscribe to chat channel: $channelName',
        );
      }
    } catch (e) {
      _logger.e(
        'MessageProvider: Error subscribing to chat channel $channelName: $e',
      );
    }
  }

  // Update the setCurrentConversation method to avoid duplicate subscriptions
  Future<void> setCurrentConversation(
    String currentUserId,
    String recipientId,
  ) async {
    final conversation = _allConversations.firstWhere(
      (conv) =>
          conv.participants.any((user) => user.id == currentUserId) &&
          conv.participants.any((user) => user.id == recipientId),
      orElse: () => Conversation(id: '', participants: [], messages: []),
    );

    if (conversation.id.isNotEmpty) {
      _currentConversationId = conversation.id;
      _currentRecipientId = recipientId;

      // Only fetch messages if we don't already have them or if they're outdated
      if (_currentMessages.isEmpty ||
          conversation.messages.length != _currentMessages.length) {
        await _fetchMessages(conversation.id);
      } else {
        // Use existing messages from conversation
        _currentMessages = conversation.messages;
      }

      // Subscribe to messages (this method already checks for duplicates)
      await _subscribeToMessages(conversation.id);
      notifyListeners();
    }
  }

  void _handleMessageSentEvent(PusherEvent event, String conversationId) {
    try {
      if (event.data is! String) {
        _logger.w(
          'MessageProvider: Invalid message.sent event data. Expected String, got ${event.data.runtimeType}',
        );
        return;
      }

      final Map<String, dynamic> eventData =
          jsonDecode(event.data) as Map<String, dynamic>;
      final newMessage = Message.fromJson(eventData);

      _logger.i(
        'MessageProvider: Received new message for conversation $conversationId',
      );

      // Add to current messages if this is the active conversation
      if (_currentConversationId == conversationId) {
        // Check if message already exists to avoid duplicates
        final existingIndex = _currentMessages.indexWhere(
          (msg) => msg.id == newMessage.id,
        );
        if (existingIndex == -1) {
          _currentMessages.add(newMessage);
        }
      }

      // Update conversation in allConversations
      final convIndex = _allConversations.indexWhere(
        (conv) => conv.id == conversationId,
      );
      if (convIndex != -1) {
        // Check if message already exists in conversation
        final existingMsgIndex = _allConversations[convIndex].messages
            .indexWhere((msg) => msg.id == newMessage.id);

        if (existingMsgIndex == -1) {
          final updatedMessages = [
            newMessage,
            ..._allConversations[convIndex].messages,
          ];
          _allConversations[convIndex] = Conversation(
            id: _allConversations[convIndex].id,
            participants: _allConversations[convIndex].participants,
            messages: updatedMessages,
          );
        }
      }

      notifyListeners();
    } catch (e) {
      _logger.e('MessageProvider: Error processing message.sent event: $e');
    }
  }

  void _handleMessageReadEvent(PusherEvent event, String conversationId) {
    try {
      if (event.data is! String) {
        _logger.w(
          'MessageProvider: Invalid message.read event data. Expected String, got ${event.data.runtimeType}',
        );
        return;
      }

      final Map<String, dynamic> eventData =
          jsonDecode(event.data) as Map<String, dynamic>;
      _logger.i(
        'MessageProvider: Message read event for conversation $conversationId: $eventData',
      );

      // Handle message read status update
      // You can update message read status in your UI here
      notifyListeners();
    } catch (e) {
      _logger.e('MessageProvider: Error processing message.read event: $e');
    }
  }

  void _handleMessageDeletedEvent(PusherEvent event, String conversationId) {
    try {
      if (event.data is! String) {
        _logger.w(
          'MessageProvider: Invalid message.deleted event data. Expected String, got ${event.data.runtimeType}',
        );
        return;
      }

      final Map<String, dynamic> eventData =
          jsonDecode(event.data) as Map<String, dynamic>;
      final deletedMessageId = eventData['message_id'] as String?;

      if (deletedMessageId != null) {
        _logger.i(
          'MessageProvider: Message deleted event for conversation $conversationId, message ID: $deletedMessageId',
        );

        // Remove from current messages if this is the active conversation
        if (_currentConversationId == conversationId) {
          _currentMessages.removeWhere((msg) => msg.id == deletedMessageId);
        }

        // Remove from conversation in allConversations
        final convIndex = _allConversations.indexWhere(
          (conv) => conv.id == conversationId,
        );
        if (convIndex != -1) {
          final updatedMessages =
              _allConversations[convIndex].messages
                  .where((msg) => msg.id != deletedMessageId)
                  .toList();
          _allConversations[convIndex] = Conversation(
            id: _allConversations[convIndex].id,
            participants: _allConversations[convIndex].participants,
            messages: updatedMessages,
          );
        }

        notifyListeners();
      }
    } catch (e) {
      _logger.e('MessageProvider: Error processing message.deleted event: $e');
    }
  }

  // Method to unsubscribe from a specific chat channel
  Future<void> unsubscribeFromChat(String conversationId) async {
    final channelName = 'chat.$conversationId';
    if (_subscribedChatChannels.contains(channelName)) {
      await _pusherService.unsubscribeFromChannel(channelName);
      _subscribedChatChannels.remove(channelName);
      _logger.i(
        'MessageProvider: Unsubscribed from chat channel: $channelName',
      );
    }
  }

  // Method to unsubscribe from all chat channels (useful for logout)
  Future<void> unsubscribeFromAllChats() async {
    final channelsToUnsubscribe = List<String>.from(_subscribedChatChannels);
    for (final channelName in channelsToUnsubscribe) {
      await _pusherService.unsubscribeFromChannel(channelName);
    }
    _subscribedChatChannels.clear();
    _logger.i('MessageProvider: Unsubscribed from all chat channels');
  }

  // Cleanup method to call on provider disposal
  @override
  void dispose() {
    unsubscribeFromAllChats();
    super.dispose();
  }

  // Method to refresh conversations and resubscribe to channels
  Future<void> refreshConversations() async {
    await fetchConversations();
  }
}
