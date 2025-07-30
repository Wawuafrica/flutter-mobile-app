// message_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wawu_mobile/models/chat_user.dart';
import 'package:wawu_mobile/models/conversation.dart';
import 'package:wawu_mobile/models/message.dart';
import 'package:wawu_mobile/services/api_service.dart';
import 'package:wawu_mobile/services/pusher_service.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/providers/base_provider.dart'; // Import BaseProvider
import 'package:path/path.dart' as path;
import 'dart:convert'; // Add this import at the top of your file

// MessageProvider now extends BaseProvider for standardized state management.
class MessageProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;
  final UserProvider _userProvider;

  List<Conversation> _allConversations = [];
  List<Message> _currentMessages = [];
  String _currentConversationId = '';
  String _currentRecipientId = '';
  // Removed _isLoading, _hasError, _errorMessage fields as BaseProvider handles them.
  // bool _isLoading = false;
  // bool _hasError = false;
  // String? _errorMessage;
  final Set<String> _subscribedChatChannels = {};
  final Map<String, bool> _boundEvents = {};
  final Map<String, ChatUser> _userProfileCache = {};

  MessageProvider({
    required ApiService apiService,
    required PusherService pusherService,
    required UserProvider userProvider,
  })  : _apiService = apiService,
        _pusherService = pusherService,
        _userProvider = userProvider;

  List<Conversation> get allConversations => _allConversations;
  List<Message> get currentMessages => _currentMessages;
  String get currentConversationId => _currentConversationId;
  String get currentRecipientId => _currentRecipientId;

  ChatUser? getCachedUserProfile(String userId) {
    return _userProfileCache[userId];
  }

  // _safeNotifyListeners is still useful for state changes not managed by BaseProvider methods,
  // or for ensuring listeners are notified when BaseProvider's notifyListeners might not be called
  // (e.g., if _state doesn't change but other data does).
  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  // New method to mark messages as read
  void markMessagesAsRead(String conversationId, String currentUserId) {
    bool changed = false;
    final convIndex = _allConversations.indexWhere(
      (conv) => conv.id == conversationId,
    );

    if (convIndex != -1) {
      final updatedMessagesInConv =
          _allConversations[convIndex].messages.map((msg) {
        if (msg.senderId != currentUserId && !msg.isRead) {
          changed = true;
          return msg.copyWith(isRead: true);
        }
        return msg;
      }).toList();

      if (changed) {
        final updatedConversation = _allConversations[convIndex].copyWith(
          messages: updatedMessagesInConv,
        );
        _allConversations[convIndex] = updatedConversation;
      }
    }

    // Mark current messages as read if this is the active conversation
    if (_currentConversationId == conversationId) {
      _currentMessages = _currentMessages.map((msg) {
        if (msg.senderId != currentUserId && !msg.isRead) {
          changed = true;
          return msg.copyWith(isRead: true);
        }
        return msg;
      }).toList();
    }

    if (changed) {
      _safeNotifyListeners();
      setSuccess(); // Notify BaseProvider listeners that data has been updated successfully
    }
  }

  Future<void> fetchConversations() async {
    setLoading(); // Use BaseProvider's setLoading
    try {
      final response = await _apiService.get('/chats');

      if (response['statusCode'] == 200 && response.containsKey('data')) {
        // Initialize all conversations with messages marked as read/unread based on sender
        _allConversations = (response['data'] as List<dynamic>).map((json) {
          final conversation = Conversation.fromJson(
            json as Map<String, dynamic>,
          );
          final currentUserId = _userProvider.currentUser?.uuid ?? '';
          final updatedMessages = conversation.messages.map((message) {
            // Mark messages as read if the current user is the sender
            // Or if the message is from another user and we are not in the chat yet
            return message.copyWith(
              isRead: message.senderId == currentUserId,
            );
          }).toList();
          return conversation.copyWith(messages: updatedMessages);
        }).toList();

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

        setSuccess(); // Use BaseProvider's setSuccess
      } else {
        setError(
          response['message'] ?? 'Failed to fetch conversations',
        ); // Use BaseProvider's setError
      }
    } catch (e) {
      setError(
        'Error fetching conversations: ${e.toString()}',
      ); // Use BaseProvider's setError
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
      } else {
        setError(
          'Failed to subscribe to global chat channel: $globalChannelName',
        ); // Report error
      }
    } catch (e) {
      setError(
        'Error subscribing to global chat events: ${e.toString()}',
      ); // Report error
    }
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
    } catch (e) {
      setError(
        'Error binding to global chat events: ${e.toString()}',
      ); // Report error
    }
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
        // Initialize messages in new conversation as unread by default
        final updatedMessages = newConversation.messages.map((message) {
          return message.copyWith(isRead: false);
        }).toList();

        final newConvWithReadStatus = newConversation.copyWith(
          messages: updatedMessages,
        );

        _allConversations.insert(0, newConvWithReadStatus);
        for (var participant in newConvWithReadStatus.participants) {
          if (!_userProfileCache.containsKey(participant.id)) {
            _fetchAndCacheUserProfile(participant.id);
          }
        }
        _subscribeToMessages(newConvWithReadStatus.id);
        _safeNotifyListeners();
        setSuccess(); // Notify BaseProvider listeners about the new conversation
      }
    } catch (e) {
      setError(
        'Error handling new chat created event: ${e.toString()}',
      ); // Report error
    }
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
        setSuccess(); // Indicate success for caching profile
      }
    } catch (e) {
      setError(
        'Error fetching and caching user profile: ${e.toString()}',
      ); // Report error
    }
  }

  Future<void> startConversation(
    String currentUserId,
    String recipientId, [
    String? initialMessage,
  ]) async {
    // FIX: Clear previous messages to prevent displaying stale data.
    _currentMessages = [];
    setLoading(); // Use BaseProvider's setLoading

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
        await _fetchMessages(
          existingConversation.id,
        ); // This will now fetch into a clean list
        await _subscribeToMessages(existingConversation.id);

        if (initialMessage != null && initialMessage.isNotEmpty) {
          await sendMessage(
            senderId: currentUserId,
            receiverId: recipientId,
            content: initialMessage,
          );
        }
        setSuccess(); // Use BaseProvider's setSuccess
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
        _currentMessages = []; // Already correct here, but the fix above makes it consistent
        await _subscribeToMessages(newConversation.id);

        if (initialMessage != null && initialMessage.isNotEmpty) {
          await sendMessage(
            senderId: currentUserId,
            receiverId: recipientId,
            content: initialMessage,
          );
        } else {
          // No initial message, still fetch messages (which might be empty) and mark as read
          await _fetchMessages(newConversation.id);
        }

        setSuccess(); // Use BaseProvider's setSuccess
        _safeNotifyListeners();
      } else {
        setError(
          response['message'] ?? 'Failed to create conversation',
        ); // Use BaseProvider's setError
      }
    } catch (e) {
      setError(
        'Error starting conversation: ${e.toString()}',
      ); // Use BaseProvider's setError
    }
  }

  Future<void> _fetchMessages(String conversationId) async {
    setLoading(); // Use BaseProvider's setLoading
    try {
      final response = await _apiService.get(
        '/chats/$conversationId/messages',
        options: Options(headers: {'Api-Token': '{{api_token}}'}),
      );
      if (response['statusCode'] == 200 && response.containsKey('data')) {
        _currentMessages = (response['data'] as List<dynamic>)
            .map((json) => Message.fromJson(json as Map<String, dynamic>))
            .toList();
        _currentMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // Mark all fetched messages as read for the current user
        final currentUserId = _userProvider.currentUser?.uuid ?? '';
        for (var message in _currentMessages) {
          if (message.senderId != currentUserId && !message.isRead) {
            message.isRead = true;
          }
        }

        // Also update the isRead status in the _allConversations list
        final convIndex = _allConversations.indexWhere(
          (conv) => conv.id == conversationId,
        );
        if (convIndex != -1) {
          final updatedMessagesInConv =
              _allConversations[convIndex].messages.map((msg) {
            if (msg.senderId != currentUserId && !msg.isRead) {
              return msg.copyWith(isRead: true);
            }
            return msg;
          }).toList();
          final updatedConversation = _allConversations[convIndex].copyWith(
            messages: updatedMessagesInConv,
          );
          _allConversations[convIndex] = updatedConversation;
        }

        setSuccess(); // Use BaseProvider's setSuccess
        _safeNotifyListeners();
      } else {
        setError(
          response['message'] ?? 'Failed to fetch messages',
        ); // Use BaseProvider's setError
      }
    } catch (e) {
      setError(
        'Error fetching messages: ${e.toString()}',
      ); // Use BaseProvider's setError
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
      } else {
        setError(
          'Failed to subscribe to message channel: $channelName',
        ); // Report error
      }
    } catch (e) {
      setError(
        'Error subscribing to messages: ${e.toString()}',
      ); // Report error
    }
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
    } catch (e) {
      setError(
        'Error binding to message events: ${e.toString()}',
      ); // Report error
    }
  }

  void _handleNewMessageEvent(dynamic event, String conversationId) {
    try {
      if (event.data == null || event.data.isEmpty) return;

      final Map<String, dynamic> eventData = event.data as Map<String, dynamic>;
      if (!eventData.containsKey('message')) return;

      // Parse the JSON string to get the actual message data
      final messageDataString = eventData['message'] as String;
      final Map<String, dynamic> messageData =
          json.decode(messageDataString) as Map<String, dynamic>;

      final newMessage = Message.fromJson(messageData);
      final currentUserId = _userProvider.currentUser?.uuid ?? '';

      // If the message is for the current conversation and from the other user, mark as read
      if (conversationId == _currentConversationId &&
          newMessage.senderId != currentUserId) {
        newMessage.isRead = true;
      } else {
        newMessage.isRead =
            false; // Mark as unread if not in current conversation
      }

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
        setSuccess(); // Notify BaseProvider listeners about the new message
      }

      final convIndex = _allConversations.indexWhere(
        (conv) => conv.id == conversationId,
      );
      if (convIndex != -1) {
        // Update the message in the conversation list, ensuring read status is correct
        final updatedMessagesInConv = List<Message>.from(
          _allConversations[convIndex].messages,
        );
        final existingMsgInConvIndex = updatedMessagesInConv.indexWhere(
          (m) => m.id == newMessage.id,
        );
        if (existingMsgInConvIndex != -1) {
          updatedMessagesInConv[existingMsgInConvIndex] = newMessage;
        } else {
          updatedMessagesInConv.insert(
            0,
            newMessage,
          ); // Add new message to the top
        }

        final updatedConversation = Conversation(
          id: _allConversations[convIndex].id,
          participants: _allConversations[convIndex].participants,
          messages: updatedMessagesInConv,
          lastMessage: newMessage,
          name: _allConversations[convIndex].name,
        );
        _allConversations.removeAt(convIndex);
        _allConversations.insert(0, updatedConversation);
        _safeNotifyListeners();
        setSuccess(); // Notify BaseProvider listeners about the conversation update
      }
    } catch (e) {
      setError(
        'Error handling new message event: ${e.toString()}',
      ); // Report error
    }
  }

  Future<Message?> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? mediaFilePath,
    String? mediaType,
  }) async {
    setLoading(); // Use BaseProvider's setLoading
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
      try {
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
          setSuccess(); // Indicate success for conversation creation
        } else {
          setError(
            response['message'] ?? 'Failed to create conversation',
          ); // Use BaseProvider's setError
          return null;
        }
      } catch (e) {
        setError(
          'Error creating conversation: ${e.toString()}',
        ); // Use BaseProvider's setError
        return null;
      }
    }

    final pendingMessage = Message(
      id: 'local-pending-${timestamp.millisecondsSinceEpoch}',
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: timestamp,
      isRead: true, // Sender's message is always read by sender
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
      setSuccess(); // Indicate success for adding pending message
    }

    try {
      // Create FormData based on whether media is present
      FormData formData;

      if (mediaFilePath != null && mediaFilePath.isNotEmpty) {
        // For media messages (voice notes, images, etc.)
        formData = FormData.fromMap({
          'message': content,
          'media[1][file]': await MultipartFile.fromFile(
            mediaFilePath,
            // filename: path.basename(mediaFilePath),
          ),
          'media[1][fileName]': path.basename(mediaFilePath),
        });
        // print(formData);
      } else {
        // For text-only messages
        formData = FormData.fromMap({'message': content});
      }

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
          isRead: true, // Sender's message is always read by sender
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
          final updatedMessages = List<Message>.from(
            _allConversations[convIndex].messages,
          );
          // Find and replace the pending message or add the new message
          final pendingMsgInConvIndex = updatedMessages.indexWhere(
            (m) => m.id == pendingMessage.id,
          );
          if (pendingMsgInConvIndex != -1) {
            updatedMessages[pendingMsgInConvIndex] = sentMessageWithStatus;
          } else {
            updatedMessages.insert(0, sentMessageWithStatus); // Add to the top
          }

          final updatedConversation = Conversation(
            id: _allConversations[convIndex].id,
            participants: _allConversations[convIndex].participants,
            messages: updatedMessages,
            lastMessage: sentMessageWithStatus,
            name: _allConversations[convIndex].name,
          );
          _allConversations.removeAt(convIndex);
          _allConversations.insert(0, updatedConversation);
        }

        setSuccess(); // Use BaseProvider's setSuccess
        _safeNotifyListeners();
        return sentMessageWithStatus;
      } else {
        _currentMessages.removeWhere((m) => m.id == pendingMessage.id);
        final failedMessage = pendingMessage.copyWith(
          id: 'local-failed-${timestamp.millisecondsSinceEpoch}',
          status: 'failed',
          isRead: true, // Still "read" by sender in a failed state
        );
        _currentMessages.add(failedMessage);
        setError(
          response['message'] ?? 'Failed to send message',
        ); // Use BaseProvider's setError
        _safeNotifyListeners();
        return null;
      }
    } catch (e) {
      _currentMessages.removeWhere((m) => m.id == pendingMessage.id);
      final failedMessage = pendingMessage.copyWith(
        id: 'local-failed-${timestamp.millisecondsSinceEpoch}',
        status: 'failed',
        isRead: true, // Still "read" by sender in a failed state
      );
      _currentMessages.add(failedMessage);
      setError(
        'Error sending message: ${e.toString()}',
      ); // Use BaseProvider's setError
      _safeNotifyListeners();
      return null;
    }
  }

  void deleteMessage(String messageId) {
    _currentMessages.removeWhere((m) => m.id == messageId);
    _safeNotifyListeners();
    setSuccess(); // Indicate success for message deletion
  }

  Future<void> setCurrentConversation(
    String currentUserId,
    String recipientId,
  ) async {
    // FIX: Immediately clear the current messages to avoid showing stale data.
    _currentMessages = [];
    // Notify listeners so the UI can update to an empty/loading state.
    _safeNotifyListeners();

    final conversation = _allConversations.firstWhere(
      (conv) =>
          conv.participants.any((user) => user.id == currentUserId) &&
          conv.participants.any((user) => user.id == recipientId),
      orElse: () => Conversation(id: '', participants: [], messages: []),
    );

    if (conversation.id.isNotEmpty) {
      _currentConversationId = conversation.id;
      _currentRecipientId = recipientId;
      // Always fetch messages to ensure the latest state and mark as read
      await _fetchMessages(conversation.id);
      await _subscribeToMessages(conversation.id);
      _safeNotifyListeners();
      setSuccess(); // Indicate success for setting current conversation
    }
  }

  Future<void> unsubscribeFromChat(String conversationId) async {
    final channelName = 'chat.$conversationId';
    if (_subscribedChatChannels.contains(channelName)) {
      await _pusherService.unsubscribeFromChannel(channelName);
      _subscribedChatChannels.remove(channelName);
      _boundEvents.removeWhere((key, value) => key.startsWith(channelName));
      setSuccess(); // Indicate success for unsubscribing
    }
  }

  Future<void> unsubscribeFromAllChats() async {
    final channelsToUnsubscribe = List<String>.from(_subscribedChatChannels);
    for (final channelName in channelsToUnsubscribe) {
      await _pusherService.unsubscribeFromChannel(channelName);
    }
    _subscribedChatChannels.clear();
    _boundEvents.clear();
    setSuccess(); // Indicate success for unsubscribing from all chats
  }

  void clearError() {
    resetState();
  }

  void clearAllMessages() {
    // Clear all conversations
    _allConversations = [];

    // Clear current messages and conversation state
    _currentMessages = [];
    _currentConversationId = '';
    _currentRecipientId = '';

    // Clear user profile cache
    _userProfileCache.clear();

    // Unsubscribe from all chat channels
    unsubscribeFromAllChats();

    // Reset provider state and notify listeners
    resetState();
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    // Removed manual _isLoading = false; _hasError = false; as BaseProvider's dispose handles state reset.
    unsubscribeFromAllChats().then((_) {
      super.dispose();
    });
  }

  Future<void> refreshConversations() async {
    await fetchConversations();
  }
}