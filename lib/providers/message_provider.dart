import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wawu_mobile/models/chat_user.dart';
import 'package:wawu_mobile/models/conversation.dart';
import 'package:wawu_mobile/models/message.dart';
import 'package:wawu_mobile/services/api_service.dart';
import 'package:wawu_mobile/services/pusher_service.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

class MessageProvider extends ChangeNotifier {
  final ApiService _apiService;
  final PusherService _pusherService;
  final UserProvider _userProvider;
  final Logger _logger = Logger();

  List<Conversation> _allConversations = [];
  List<Message> _currentMessages = [];
  String _currentConversationId = '';
  String _currentRecipientId = '';
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  final Set<String> _subscribedChatChannels = {};
  final Map<String, bool> _boundEvents = {};

  // Cache for user profiles
  final Map<String, ChatUser> _userProfileCache = {};

  MessageProvider({
    required ApiService apiService,
    required PusherService pusherService,
    required UserProvider userProvider,
  }) : _apiService = apiService,
       _pusherService = pusherService,
       _userProvider = userProvider;

  List<Conversation> get allConversations => _allConversations;
  List<Message> get currentMessages => _currentMessages;
  String get currentConversationId => _currentConversationId;
  String get currentRecipientId => _currentRecipientId;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  // Get cached user profile
  ChatUser? getCachedUserProfile(String userId) {
    return _userProfileCache[userId];
  }

  // Safe wrapper for notifyListeners to avoid build-time calls
  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setLoading() {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void setError(String message) {
    _isLoading = false;
    _hasError = true;
    _errorMessage = message;
    _logger.e('MessageProvider Error: $message');
    _safeNotifyListeners();
  }

  void setSuccess() {
    _isLoading = false;
    _hasError = false;
    _errorMessage = null;
    _safeNotifyListeners();
  }

  Future<void> fetchConversations() async {
    _logger.i('=== STARTING FETCH CONVERSATIONS ===');
    setLoading();
    try {
      final response = await _apiService.get('/chats');

      if (response['statusCode'] == 200 && response.containsKey('data')) {
        _allConversations =
            (response['data'] as List<dynamic>)
                .map(
                  (json) => Conversation.fromJson(json as Map<String, dynamic>),
                )
                .toList();

        _logger.i('Found ${_allConversations.length} conversations');

        // Fetch user profiles for all participants
        for (var conv in _allConversations) {
          _logger.d('Processing conversation: ${conv.id}');
          for (var participant in conv.participants) {
            if (!_userProfileCache.containsKey(participant.id)) {
              await _fetchAndCacheUserProfile(participant.id);
            }
          }
        }

        // Subscribe to all conversation channels
        for (final conversation in _allConversations) {
          _logger.i('Subscribing to conversation: ${conversation.id}');
          await _subscribeToMessages(conversation.id);
        }

        setSuccess();
        _logger.i(
          '=== SUCCESSFULLY FETCHED ${_allConversations.length} CONVERSATIONS ===',
        );
      } else {
        setError(response['message'] ?? 'Failed to fetch conversations');
      }
    } catch (e) {
      _logger.e('Error fetching conversations: $e');
      setError('Error fetching conversations: $e');
    }
  }

  Future<void> _fetchAndCacheUserProfile(String userId) async {
    if (userId.isEmpty || _userProfileCache.containsKey(userId)) return;

    try {
      dynamic user;
      try {
        if (_userProvider.viewedUser?.uuid == userId) {
          user = _userProvider.viewedUser;
        } else {
          await _userProvider.fetchUserById(userId);
          if (_userProvider.viewedUser?.uuid == userId) {
            user = _userProvider.viewedUser;
          }
        }
      } catch (e) {
        _logger.e('Error accessing user from provider: $e');
      }
      if (user != null) {
        _userProfileCache[userId] = ChatUser(
          id: user.uuid,
          name: '${user.firstName} ${user.lastName}',
          avatar: user.profileImage ?? '',
        );
        _logger.d('Cached user profile for: ${user.uuid}');
      }
    } catch (e) {
      _logger.e('Error fetching user profile for ID $userId: $e');
    }
  }

  Future<void> startConversation(
    String currentUserId,
    String recipientId, [
    String? initialMessage,
  ]) async {
    _logger.i('=== STARTING CONVERSATION ===');
    _logger.i('Current User: $currentUserId');
    _logger.i('Recipient: $recipientId');
    _logger.i('Initial Message: $initialMessage');

    setLoading();
    try {
      await _fetchAndCacheUserProfile(recipientId);

      // Check for existing conversation
      final existingConversation = _allConversations.firstWhere(
        (conv) =>
            conv.participants.any((user) => user.id == currentUserId) &&
            conv.participants.any((user) => user.id == recipientId),
        orElse: () => Conversation(id: '', participants: [], messages: []),
      );

      if (existingConversation.id.isNotEmpty) {
        _logger.i('Found existing conversation: ${existingConversation.id}');
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
      _logger.i('Creating new conversation...');
      final response = await _apiService.post(
        '/chats',
        data: {'user_id': recipientId},
        options: Options(headers: {'Api-Token': '{{api_token}}'}),
      );

      _logger.d('Create conversation response: $response');

      if (response['statusCode'] == 200 && response.containsKey('data')) {
        try {
          final newConversation = Conversation.fromJson(
            response['data'] as Map<String, dynamic>,
          );

          _allConversations.add(newConversation);
          _currentConversationId = newConversation.id;
          _currentRecipientId = recipientId;
          _currentMessages = [];

          _logger.i('Created new conversation: ${newConversation.id}');

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
          _safeNotifyListeners();
          _logger.i('=== CONVERSATION STARTED SUCCESSFULLY ===');
        } catch (jsonError) {
          _logger.e('JSON parsing error: $jsonError');
          _logger.e('Raw response data: ${response['data']}');
          setError('Failed to parse conversation data: $jsonError');
          return;
        }
      } else {
        setError(response['message'] ?? 'Failed to create conversation');
      }
    } catch (e) {
      _logger.e('Full error details: $e');
      setError('Error starting conversation: $e');
    }
  }

  Future<void> _fetchMessages(String conversationId) async {
    _logger.i('=== FETCHING MESSAGES FOR CONVERSATION: $conversationId ===');
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
        _currentMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        setSuccess();
        _logger.i(
          'Fetched ${_currentMessages.length} messages for conversation $conversationId',
        );
        _safeNotifyListeners();
      } else {
        setError(response['message'] ?? 'Failed to fetch messages');
      }
    } catch (e) {
      _logger.e('Error fetching messages: $e');
      setError('Error fetching messages: $e');
    }
  }

  Future<void> _subscribeToMessages(String conversationId) async {
    _logger.i('=== SUBSCRIBING TO MESSAGES ===');
    _logger.i('Conversation ID: $conversationId');
    _logger.i('PusherService initialized: ${_pusherService.isInitialized}');

    if (!_pusherService.isInitialized) {
      _logger.e(
        '❌ PusherService not initialized, cannot subscribe to messages',
      );
      return;
    }

    final channelName = 'chat.$conversationId';
    _logger.i('Channel name: $channelName');

    // Check if already subscribed
    if (_subscribedChatChannels.contains(channelName)) {
      _logger.w('Already subscribed to channel: $channelName');
      return;
    }

    try {
      _logger.i('Attempting to subscribe to channel: $channelName');
      final success = await _pusherService.subscribeToChannel(channelName);

      if (success) {
        _subscribedChatChannels.add(channelName);
        _logger.i('✅ Successfully subscribed to chat channel: $channelName');

        // Bind to message events for real-time updates
        await _bindToMessageEvents(channelName, conversationId);

        _logger.i('=== SUBSCRIPTION COMPLETE ===');
      } else {
        _logger.e('❌ Failed to subscribe to chat channel: $channelName');
      }
    } catch (e) {
      _logger.e('❌ Error subscribing to chat channel $channelName: $e');
    }
  }

  Future<void> _bindToMessageEvents(
    String channelName,
    String conversationId,
  ) async {
    _logger.i('=== BINDING TO MESSAGE EVENTS ===');
    _logger.i('Channel: $channelName');
    _logger.i('Conversation: $conversationId');

    final eventKey = '$channelName.message.sent';

    if (_boundEvents.containsKey(eventKey) && _boundEvents[eventKey] == true) {
      _logger.w('Already bound to event: $eventKey');
      return;
    }

    try {
      _logger.i('Binding to event: message.sent');
      _pusherService.bindToEvent(channelName, 'message.sent', (event) {
        _logger.i('🔥 RECEIVED MESSAGE.SENT EVENT!');
        _logger.i('Event data: ${event?.data}');
        _handleNewMessageEvent(event, conversationId);
      });

      _boundEvents[eventKey] = true;
      _logger.i('✅ Successfully bound to event for channel: $channelName');
      _logger.i('=== EVENT BINDING COMPLETE ===');
    } catch (e) {
      _logger.e('❌ Error binding to events for channel $channelName: $e');
    }
  }

  void _handleNewMessageEvent(dynamic event, String conversationId) {
    _logger.i('🔥🔥🔥 HANDLING NEW MESSAGE EVENT 🔥🔥🔥');
    _logger.i('Conversation ID: $conversationId');
    _logger.i('Current Conversation ID: $_currentConversationId');
    _logger.i('Event data: ${event?.data}');

    try {
      if (event.data == null || event.data.isEmpty) {
        _logger.w('❌ Received empty event data for message.sent');
        return;
      }

      final Map<String, dynamic> eventData =
          jsonDecode(event.data) as Map<String, dynamic>;
      _logger.i('Parsed event data: $eventData');

      final newMessage = Message.fromJson(eventData);
      _logger.i('New message parsed: ${newMessage.id} - ${newMessage.content}');

      // Check if this message is for the current conversation
      if (conversationId == _currentConversationId) {
        _logger.i('Message is for current conversation, processing...');

        // Check if message already exists
        final existingMessageIndex = _currentMessages.indexWhere(
          (m) => m.id == newMessage.id,
        );

        if (existingMessageIndex == -1) {
          _currentMessages.add(newMessage);
          _currentMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _logger.i('✅ Added new message to current messages');
          _safeNotifyListeners();
        } else {
          _logger.w('Message already exists, skipping: ${newMessage.id}');
        }
      } else {
        _logger.i(
          'Message is not for current conversation, updating conversations list only',
        );
      }

      // Update the conversation's last message
      final convIndex = _allConversations.indexWhere(
        (conv) => conv.id == conversationId,
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
          lastMessage: newMessage,
        );
        _logger.i('✅ Updated conversation last message');
        _safeNotifyListeners();
      }

      _logger.i('🔥🔥🔥 MESSAGE EVENT HANDLED SUCCESSFULLY 🔥🔥🔥');
    } catch (e) {
      _logger.e('❌ Error processing message.sent event: $e');
      _logger.e('Event data was: ${event?.data}');
    }
  }

  // Add a method to test if events are working
  Future<void> testRealTimeConnection() async {
    _logger.i('=== TESTING REAL-TIME CONNECTION ===');
    _logger.i('PusherService initialized: ${_pusherService.isInitialized}');
    _logger.i('Subscribed channels: $_subscribedChatChannels');
    _logger.i('Bound events: $_boundEvents');
    _logger.i('Current conversation ID: $_currentConversationId');

    if (_currentConversationId.isNotEmpty) {
      final channelName = 'chat.$_currentConversationId';
      _logger.i('Testing channel: $channelName');

      // Try to trigger a test event or log connection status
      // This would depend on your PusherService implementation
      _logger.i('=== TEST COMPLETE ===');
    }
  }

  Future<Message?> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? mediaFilePath,
    String? mediaType,
  }) async {
    _logger.i('=== SENDING MESSAGE ===');
    _logger.i('Sender: $senderId');
    _logger.i('Receiver: $receiverId');
    _logger.i('Content: $content');

    setLoading();
    String targetConversationId = '';

    // Find or create conversation logic
    final conversation = _allConversations.firstWhere(
      (conv) =>
          conv.participants.any((user) => user.id == senderId) &&
          conv.participants.any((user) => user.id == receiverId),
      orElse: () => Conversation(id: '', participants: [], messages: []),
    );

    if (conversation.id.isNotEmpty) {
      targetConversationId = conversation.id;
      _logger.i('Using existing conversation: $targetConversationId');
    } else {
      _logger.i('Creating new conversation...');
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
        await _subscribeToMessages(newConversation.id);
        _safeNotifyListeners();
        _logger.i('Created new conversation: $targetConversationId');
      } else {
        setError(response['message'] ?? 'Failed to create conversation');
        return null;
      }
    }

    // Optimistic UI
    final pendingMessage = Message(
      id: 'local-pending-${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
      attachmentUrl: mediaFilePath,
      attachmentType: mediaType,
      status: 'pending',
    );

    _currentMessages.add(pendingMessage);
    _safeNotifyListeners();

    try {
      final formData = FormData.fromMap({
        'message': content,
        if (mediaFilePath != null)
          'media[file]': await MultipartFile.fromFile(mediaFilePath),
        if (mediaFilePath != null)
          'media[fileName]': path.basename(mediaFilePath),
      });

      _logger.i('Sending message to API...');
      final response = await _apiService.post(
        '/chats/$targetConversationId/messages',
        data: formData,
        options: Options(headers: {'Api-Token': '{{api_token}}'}),
      );

      _logger.i('Send message API response: $response');

      if (response['statusCode'] == 200 && response.containsKey('data')) {
        final sentMessage = Message.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        _currentMessages.removeWhere((m) => m.id == pendingMessage.id);

        final sentMessageWithStatus = Message(
          id: sentMessage.id,
          senderId: sentMessage.senderId,
          receiverId: sentMessage.receiverId,
          content: sentMessage.content,
          timestamp: sentMessage.timestamp,
          isRead: sentMessage.isRead,
          attachmentUrl: sentMessage.attachmentUrl,
          attachmentType: sentMessage.attachmentType,
          status: 'sent',
        );

        _currentMessages.add(sentMessageWithStatus);
        _currentMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // Update conversation
        final convIndex = _allConversations.indexWhere(
          (conv) => conv.id == targetConversationId,
        );
        if (convIndex != -1) {
          final updatedMessages = [
            sentMessageWithStatus,
            ..._allConversations[convIndex].messages,
          ];
          _allConversations[convIndex] = Conversation(
            id: _allConversations[convIndex].id,
            participants: _allConversations[convIndex].participants,
            messages: updatedMessages,
            lastMessage: sentMessageWithStatus,
          );
        }

        setSuccess();
        _safeNotifyListeners();
        _logger.i('✅ Message sent successfully: ${sentMessage.id}');
        return sentMessageWithStatus;
      } else {
        _logger.e('❌ API error: ${response['message']}');
        _currentMessages.removeWhere((m) => m.id == pendingMessage.id);

        final failedMessage = Message(
          id: 'local-failed-${DateTime.now().millisecondsSinceEpoch}',
          senderId: senderId,
          receiverId: receiverId,
          content: content,
          timestamp: DateTime.now(),
          isRead: false,
          attachmentUrl: mediaFilePath,
          attachmentType: mediaType,
          status: 'failed',
        );

        _currentMessages.add(failedMessage);
        _safeNotifyListeners();
        return null;
      }
    } catch (e) {
      _logger.e('❌ Error sending message: $e');
      _currentMessages.removeWhere((m) => m.id.startsWith('local-pending-'));
      _safeNotifyListeners();
      return null;
    }
  }

  void deleteMessage(String messageId) {
    _currentMessages.removeWhere((m) => m.id == messageId);
    _safeNotifyListeners();
  }

  Future<void> setCurrentConversation(
    String currentUserId,
    String recipientId,
  ) async {
    _logger.i('=== SETTING CURRENT CONVERSATION ===');
    _logger.i('Current User: $currentUserId');
    _logger.i('Recipient: $recipientId');

    final conversation = _allConversations.firstWhere(
      (conv) =>
          conv.participants.any((user) => user.id == currentUserId) &&
          conv.participants.any((user) => user.id == recipientId),
      orElse: () => Conversation(id: '', participants: [], messages: []),
    );

    if (conversation.id.isNotEmpty) {
      _currentConversationId = conversation.id;
      _currentRecipientId = recipientId;
      _logger.i('Set current conversation: $_currentConversationId');

      if (_currentMessages.isEmpty ||
          conversation.messages.length != _currentMessages.length) {
        await _fetchMessages(conversation.id);
      } else {
        _currentMessages = conversation.messages;
      }

      await _subscribeToMessages(conversation.id);
      _safeNotifyListeners();
    } else {
      _logger.w(
        'No conversation found for users: $currentUserId and $recipientId',
      );
    }
  }

  Future<void> unsubscribeFromChat(String conversationId) async {
    final channelName = 'chat.$conversationId';
    if (_subscribedChatChannels.contains(channelName)) {
      await _pusherService.unsubscribeFromChannel(channelName);
      _subscribedChatChannels.remove(channelName);
      _boundEvents.removeWhere((key, value) => key.startsWith(channelName));
      _logger.i('Unsubscribed from chat channel: $channelName');
    }
  }

  Future<void> unsubscribeFromAllChats() async {
    final channelsToUnsubscribe = List<String>.from(_subscribedChatChannels);
    for (final channelName in channelsToUnsubscribe) {
      await _pusherService.unsubscribeFromChannel(channelName);
    }
    _subscribedChatChannels.clear();
    _boundEvents.clear();
    _logger.i('Unsubscribed from all chat channels');
  }

  @override
  void dispose() {
    _isLoading = false;
    _hasError = false;
    unsubscribeFromAllChats().then((_) {
      super.dispose();
    });
  }

  Future<void> refreshConversations() async {
    await fetchConversations();
  }
}
