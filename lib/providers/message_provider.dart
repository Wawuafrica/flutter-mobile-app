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
  final Set<String> _subscribedChatChannels =
      {}; // Track subscribed chat channels

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

        // Fetch user profiles for all participants
        for (var conv in _allConversations) {
          for (var participant in conv.participants) {
            if (!_userProfileCache.containsKey(participant.id)) {
              await _fetchAndCacheUserProfile(participant.id);
            }
          }
        }

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

  Future<void> _fetchAndCacheUserProfile(String userId) async {
    if (userId.isEmpty || _userProfileCache.containsKey(userId)) return;

    try {
      dynamic user;
      try {
        // Attempting to use a generic method or property that might exist
        if (_userProvider.viewedUser?.uuid == userId) {
          user = _userProvider.viewedUser;
        } else {
          // Fallback to triggering a fetch if possible
          await _userProvider.fetchUserById(userId);
          if (_userProvider.viewedUser?.uuid == userId) {
            user = _userProvider.viewedUser;
          }
        }
      } catch (e) {
        print('Error accessing user from provider: $e');
      }
      if (user != null) {
        _userProfileCache[userId] = ChatUser(
          id: user.uuid,
          name: '${user.firstName} ${user.lastName}',
          avatar: user.profileImage ?? '',
        );
      }
    } catch (e) {
      print('Error fetching user profile for ID $userId: $e');
    }
  }

  Future<void> startConversation(
    String currentUserId,
    String recipientId, [
    String? initialMessage,
  ]) async {
    setLoading();
    try {
      // Fetch recipient profile if not in cache
      await _fetchAndCacheUserProfile(recipientId);

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
        // Sort messages by timestamp ascending (oldest first)
        _currentMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        setSuccess();
        _logger.i(
          'MessageProvider: Fetched ${_currentMessages.length} messages for conversation $conversationId',
        );
        notifyListeners();
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
    String targetConversationId = '';
    // Find or create conversation logic here, ensuring targetConversationId is set before use
    final conversation = _allConversations.firstWhere(
      (conv) =>
          conv.participants.any((user) => user.id == senderId) &&
          conv.participants.any((user) => user.id == receiverId),
      orElse: () => Conversation(id: '', participants: [], messages: []),
    );
    if (conversation.id.isNotEmpty) {
      targetConversationId = conversation.id;
    } else {
      // Create new conversation if not found
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
        notifyListeners();
      } else {
        setError(response['message'] ?? 'Failed to create conversation');
        return null;
      }
    }
    // Optimistic UI: Add message with pending status locally
    final pendingMessage = Message(
      id: 'local-pending-${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
      attachmentUrl: mediaFilePath,
      attachmentType: mediaType,
      status: 'pending', // Set status to 'pending' using new field
    );
    _currentMessages.add(pendingMessage);
    notifyListeners();
    try {
      final formData = FormData.fromMap({
        'message': content,
        if (mediaFilePath != null)
          'media[file]': await MultipartFile.fromFile(mediaFilePath),
        if (mediaFilePath != null)
          'media[fileName]': path.basename(mediaFilePath),
      });
      _logger.i(
        'SendMessage request payload: $formData',
      ); // Log request payload
      final response = await _apiService.post(
        '/chats/$targetConversationId/messages',
        data: formData,
        options: Options(headers: {'Api-Token': '{{api_token}}'}),
      );
      _logger.i('API response for sendMessage: $response'); // Log full response
      if (response['statusCode'] == 200 && response.containsKey('data')) {
        final sentMessage = Message.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        _currentMessages.removeWhere((m) => m.id == pendingMessage.id);
        final sentMessageWithStatus = Message(
          // Create sent message with status
          id: sentMessage.id,
          senderId: sentMessage.senderId,
          receiverId: sentMessage.receiverId,
          content: sentMessage.content,
          timestamp: sentMessage.timestamp,
          isRead: sentMessage.isRead,
          attachmentUrl: sentMessage.attachmentUrl,
          attachmentType: sentMessage.attachmentType,
          status: 'sent', // Set status to 'sent'
        );
        _currentMessages.add(sentMessageWithStatus);
        // Sort messages after adding new one
        _currentMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
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
        } else {
          _allConversations.add(
            Conversation(
              id: targetConversationId,
              participants: [
                ChatUser(id: senderId, name: '', avatar: null),
                ChatUser(id: receiverId, name: '', avatar: null),
              ],
              messages: [sentMessageWithStatus],
              lastMessage: sentMessageWithStatus,
            ),
          );
        }
        setSuccess();
        notifyListeners();
        _logger.i('Message sent successfully');
        return sentMessageWithStatus;
      } else {
        _logger.e(
          'API error: ${response['message'] ?? 'Unknown error'} with payload: $formData',
        );
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
          status: 'failed', // Set status to 'failed' using new field
        );
        _currentMessages.add(failedMessage);
        notifyListeners();
        return null;
      }
    } catch (e) {
      _logger.e('Error sending message: $e');
      _currentMessages.removeWhere((m) => m.id.startsWith('local-pending-'));
      notifyListeners();
      return null;
    }
  }

  void deleteMessage(String messageId) {
    _currentMessages.removeWhere((m) => m.id == messageId);
    notifyListeners();
  }

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

  Future<void> unsubscribeFromAllChats() async {
    final channelsToUnsubscribe = List<String>.from(_subscribedChatChannels);
    for (final channelName in channelsToUnsubscribe) {
      await _pusherService.unsubscribeFromChannel(channelName);
    }
    _subscribedChatChannels.clear();
    _logger.i('MessageProvider: Unsubscribed from all chat channels');
  }

  @override
  void dispose() {
    // Cancel any ongoing operations
    _isLoading = false;
    _hasError = false;

    // Unsubscribe from all channels before disposing
    unsubscribeFromAllChats().then((_) {
      super.dispose();
    });
  }

  Future<void> refreshConversations() async {
    await fetchConversations();
  }
}
