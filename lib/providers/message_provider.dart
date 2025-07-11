import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wawu_mobile/models/chat_user.dart';
import 'package:wawu_mobile/models/conversation.dart';
import 'package:wawu_mobile/models/message.dart';
import 'package:wawu_mobile/services/api_service.dart';
import 'package:wawu_mobile/services/pusher_service.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:path/path.dart' as path;

class MessageProvider extends ChangeNotifier {
  final ApiService _apiService;
  final PusherService _pusherService;
  final UserProvider _userProvider;

  List<Conversation> _allConversations = [];
  List<Message> _currentMessages = [];
  String _currentConversationId = '';
  String _currentRecipientId = '';
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  final Set<String> _subscribedChatChannels = {};
  final Map<String, bool> _boundEvents = {};
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

  ChatUser? getCachedUserProfile(String userId) {
    return _userProfileCache[userId];
  }

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
    _safeNotifyListeners();
  }

  void setSuccess() {
    _isLoading = false;
    _hasError = false;
    _errorMessage = null;
    _safeNotifyListeners();
  }

  Future<void> fetchConversations() async {
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

        for (var conv in _allConversations) {
          for (var participant in conv.participants) {
            if (!_userProfileCache.containsKey(participant.id)) {
              await _fetchAndCacheUserProfile(participant.id);
            }
          }
        }

        await _subscribeToGlobalChatEvents();
        for (final conversation in _allConversations) {
          await _subscribeToMessages(conversation.id);
        }

        setSuccess();
      } else {
        setError(response['message'] ?? 'Failed to fetch conversations');
      }
    } catch (e) {
      setError('Error fetching conversations: $e');
    }
  }

  Future<void> _subscribeToGlobalChatEvents() async {
    if (!_pusherService.isInitialized) return;

    final currentUserId = _userProvider.currentUser?.uuid;
    if (currentUserId == null) return;

    final globalChannelName = 'chat.created.$currentUserId';
    if (_subscribedChatChannels.contains(globalChannelName)) return;

    try {
      final success = await _pusherService.subscribeToChannel(
        globalChannelName,
      );
      if (success) {
        _subscribedChatChannels.add(globalChannelName);
        await _bindToGlobalChatEvents(globalChannelName);
      }
    } catch (e) {}
  }

  Future<void> _bindToGlobalChatEvents(String channelName) async {
    final eventKey = '$channelName.chat.created';
    if (_boundEvents.containsKey(eventKey) && _boundEvents[eventKey] == true)
      return;

    try {
      _pusherService.bindToEvent(channelName, 'chat.created', (event) {
        _handleNewChatCreatedEvent(event);
      });
      _boundEvents[eventKey] = true;
    } catch (e) {}
  }

  void _handleNewChatCreatedEvent(dynamic event) {
    try {
      if (event.data == null || event.data.isEmpty) return;

      final Map<String, dynamic> eventData = event.data as Map<String, dynamic>;
      final newConversation = Conversation.fromJson(eventData);
      final existingIndex = _allConversations.indexWhere(
        (conv) => conv.id == newConversation.id,
      );

      if (existingIndex == -1) {
        _allConversations.insert(0, newConversation);
        for (var participant in newConversation.participants) {
          if (!_userProfileCache.containsKey(participant.id)) {
            _fetchAndCacheUserProfile(participant.id);
          }
        }
        _subscribeToMessages(newConversation.id);
        _safeNotifyListeners();
      }
    } catch (e) {}
  }

  Future<void> _fetchAndCacheUserProfile(String userId) async {
    if (userId.isEmpty || _userProfileCache.containsKey(userId)) return;

    try {
      dynamic user;
      if (_userProvider.viewedUser?.uuid == userId) {
        user = _userProvider.viewedUser;
      } else {
        await _userProvider.fetchUserById(userId);
        if (_userProvider.viewedUser?.uuid == userId) {
          user = _userProvider.viewedUser;
        }
      }
      if (user != null) {
        _userProfileCache[userId] = ChatUser(
          id: user.uuid,
          name: '${user.firstName} ${user.lastName}',
          avatar: user.profileImage ?? '',
        );
      }
    } catch (e) {}
  }

  Future<void> startConversation(
    String currentUserId,
    String recipientId, [
    String? initialMessage,
  ]) async {
    setLoading();
    try {
      await _fetchAndCacheUserProfile(recipientId);
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

      final response = await _apiService.post(
        '/chats',
        data: {'user_id': recipientId},
        options: Options(headers: {'Api-Token': '{{api_token}}'}),
      );

      if (response['statusCode'] == 200 && response.containsKey('data')) {
        final newConversation = Conversation.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        _allConversations.insert(0, newConversation);
        _currentConversationId = newConversation.id;
        _currentRecipientId = recipientId;
        _currentMessages = [];
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
      } else {
        setError(response['message'] ?? 'Failed to create conversation');
      }
    } catch (e) {
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
        _currentMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        setSuccess();
        _safeNotifyListeners();
      } else {
        setError(response['message'] ?? 'Failed to fetch messages');
      }
    } catch (e) {
      setError('Error fetching messages: $e');
    }
  }

  Future<void> _subscribeToMessages(String conversationId) async {
    if (!_pusherService.isInitialized) return;

    final channelName = 'chat.$conversationId';
    if (_subscribedChatChannels.contains(channelName)) return;

    try {
      final success = await _pusherService.subscribeToChannel(channelName);
      if (success) {
        _subscribedChatChannels.add(channelName);
        await _bindToMessageEvents(channelName, conversationId);
      }
    } catch (e) {}
  }

  Future<void> _bindToMessageEvents(
    String channelName,
    String conversationId,
  ) async {
    final eventKey = '$channelName.message.sent';
    if (_boundEvents.containsKey(eventKey) && _boundEvents[eventKey] == true)
      return;

    try {
      _pusherService.bindToEvent(channelName, 'message.sent', (event) {
        _handleNewMessageEvent(event, conversationId);
      });
      _boundEvents[eventKey] = true;
    } catch (e) {}
  }

  void _handleNewMessageEvent(dynamic event, String conversationId) {
    try {
      if (event.data == null || event.data.isEmpty) return;

      final Map<String, dynamic> eventData = event.data as Map<String, dynamic>;
      if (!eventData.containsKey('message')) return;

      final messageData = eventData['message'] as Map<String, dynamic>;
      final newMessage = Message.fromJson(messageData);

      if (conversationId == _currentConversationId) {
        final pendingMessageIndex = _currentMessages.indexWhere(
          (m) =>
              m.id.startsWith('local-pending-') &&
              m.senderId == newMessage.senderId &&
              m.receiverId == newMessage.receiverId &&
              m.content == newMessage.content &&
              m.timestamp.millisecondsSinceEpoch ==
                  newMessage.timestamp.millisecondsSinceEpoch,
        );

        if (pendingMessageIndex != -1) {
          _currentMessages[pendingMessageIndex] = newMessage;
        } else {
          final existingMessageIndex = _currentMessages.indexWhere(
            (m) => m.id == newMessage.id,
          );
          if (existingMessageIndex == -1) {
            _currentMessages.add(newMessage);
          }
        }
        _currentMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _safeNotifyListeners();
      }

      final convIndex = _allConversations.indexWhere(
        (conv) => conv.id == conversationId,
      );
      if (convIndex != -1) {
        final updatedConversation = Conversation(
          id: _allConversations[convIndex].id,
          participants: _allConversations[convIndex].participants,
          messages: [newMessage, ..._allConversations[convIndex].messages],
          lastMessage: newMessage,
          name: _allConversations[convIndex].name,
        );
        _allConversations.removeAt(convIndex);
        _allConversations.insert(0, updatedConversation);
        _safeNotifyListeners();
      }
    } catch (e) {}
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
    final timestamp = DateTime.now();

    final conversation = _allConversations.firstWhere(
      (conv) =>
          conv.participants.any((user) => user.id == senderId) &&
          conv.participants.any((user) => user.id == receiverId),
      orElse: () => Conversation(id: '', participants: [], messages: []),
    );

    if (conversation.id.isNotEmpty) {
      targetConversationId = conversation.id;
    } else {
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
        _allConversations.insert(0, newConversation);
        targetConversationId = newConversation.id;
        _currentConversationId = newConversation.id;
        _currentRecipientId = receiverId;
        await _subscribeToMessages(newConversation.id);
        _safeNotifyListeners();
      } else {
        setError(response['message'] ?? 'Failed to create conversation');
        return null;
      }
    }

    final pendingMessage = Message(
      id: 'local-pending-${timestamp.millisecondsSinceEpoch}',
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: timestamp,
      isRead: true,
      attachmentUrl: mediaFilePath,
      attachmentType: mediaType,
      status: 'pending',
    );

    final existingMessageIndex = _currentMessages.indexWhere(
      (m) =>
          m.senderId == senderId &&
          m.receiverId == receiverId &&
          m.content == content &&
          m.timestamp.millisecondsSinceEpoch ==
              timestamp.millisecondsSinceEpoch,
    );
    if (existingMessageIndex == -1) {
      _currentMessages.add(pendingMessage);
      _safeNotifyListeners();
    }

    try {
      final formData = FormData.fromMap({
        'message': content,
        if (mediaFilePath != null)
          'media[file]': await MultipartFile.fromFile(mediaFilePath),
        if (mediaFilePath != null)
          'media[fileName]': path.basename(mediaFilePath),
      });

      final response = await _apiService.post(
        '/chats/$targetConversationId/messages',
        data: formData,
        options: Options(headers: {'Api-Token': '{{api_token}}'}),
      );

      if (response['statusCode'] == 200 && response.containsKey('data')) {
        final sentMessage = Message.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        _currentMessages.removeWhere((m) => m.id == pendingMessage.id);

        final sentMessageWithStatus = sentMessage.copyWith(
          status: 'sent',
          isRead: senderId == sentMessage.senderId,
        );

        final duplicateIndex = _currentMessages.indexWhere(
          (m) => m.id == sentMessageWithStatus.id,
        );
        if (duplicateIndex == -1) {
          _currentMessages.add(sentMessageWithStatus);
          _currentMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        }

        final convIndex = _allConversations.indexWhere(
          (conv) => conv.id == targetConversationId,
        );
        if (convIndex != -1) {
          final updatedConversation = Conversation(
            id: _allConversations[convIndex].id,
            participants: _allConversations[convIndex].participants,
            messages: [
              sentMessageWithStatus,
              ..._allConversations[convIndex].messages,
            ],
            lastMessage: sentMessageWithStatus,
            name: _allConversations[convIndex].name,
          );
          _allConversations.removeAt(convIndex);
          _allConversations.insert(0, updatedConversation);
        }

        setSuccess();
        _safeNotifyListeners();
        return sentMessageWithStatus;
      } else {
        _currentMessages.removeWhere((m) => m.id == pendingMessage.id);
        final failedMessage = pendingMessage.copyWith(
          id: 'local-failed-${timestamp.millisecondsSinceEpoch}',
          status: 'failed',
        );
        _currentMessages.add(failedMessage);
        _safeNotifyListeners();
        return null;
      }
    } catch (e) {
      _currentMessages.removeWhere((m) => m.id == pendingMessage.id);
      final failedMessage = pendingMessage.copyWith(
        id: 'local-failed-${timestamp.millisecondsSinceEpoch}',
        status: 'failed',
      );
      _currentMessages.add(failedMessage);
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
    final conversation = _allConversations.firstWhere(
      (conv) =>
          conv.participants.any((user) => user.id == currentUserId) &&
          conv.participants.any((user) => user.id == recipientId),
      orElse: () => Conversation(id: '', participants: [], messages: []),
    );

    if (conversation.id.isNotEmpty) {
      _currentConversationId = conversation.id;
      _currentRecipientId = recipientId;
      if (_currentMessages.isEmpty ||
          conversation.messages.length != _currentMessages.length) {
        await _fetchMessages(conversation.id);
      } else {
        _currentMessages = conversation.messages;
      }
      await _subscribeToMessages(conversation.id);
      _safeNotifyListeners();
    }
  }

  Future<void> unsubscribeFromChat(String conversationId) async {
    final channelName = 'chat.$conversationId';
    if (_subscribedChatChannels.contains(channelName)) {
      await _pusherService.unsubscribeFromChannel(channelName);
      _subscribedChatChannels.remove(channelName);
      _boundEvents.removeWhere((key, value) => key.startsWith(channelName));
    }
  }

  Future<void> unsubscribeFromAllChats() async {
    final channelsToUnsubscribe = List<String>.from(_subscribedChatChannels);
    for (final channelName in channelsToUnsubscribe) {
      await _pusherService.unsubscribeFromChannel(channelName);
    }
    _subscribedChatChannels.clear();
    _boundEvents.clear();
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
