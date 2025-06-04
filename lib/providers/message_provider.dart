import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wawu_mobile/models/chat_user.dart';
import 'package:wawu_mobile/models/conversation.dart';
import 'package:wawu_mobile/models/message.dart';
import 'package:wawu_mobile/services/api_service.dart';
import 'package:wawu_mobile/services/pusher_service.dart';

class MessageProvider extends ChangeNotifier {
  final ApiService _apiService;
  final PusherService _pusherService;

  List<Conversation> _allConversations = [];
  List<Message> _currentMessages = [];
  String _currentConversationId = '';
  String _currentRecipientId = '';
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

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
      final response = await _apiService.get('/chats', options: Options(headers: {'Api-Token': '{{api_token}}'}));
      if (response['statusCode'] == 200 && response.containsKey('data')) {
        _allConversations = (response['data'] as List<dynamic>)
            .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
            .toList();
        setSuccess();
      } else {
        setError(response['message'] ?? 'Failed to fetch conversations');
      }
    } catch (e) {
      setError('Error fetching conversations: $e');
    }
  }

  Future<void> startConversation(String currentUserId, String recipientId, [String? initialMessage]) async {
    setLoading();
    try {
      // Check for existing conversation
      final existingConversation = _allConversations.firstWhere(
        (conv) => conv.participants.any((user) => user.id == currentUserId) &&
                  conv.participants.any((user) => user.id == recipientId),
        orElse: () => Conversation(id: '', participants: [], messages: []),
      );

      if (existingConversation.id.isNotEmpty) {
        _currentConversationId = existingConversation.id;
        _currentRecipientId = recipientId;
        await _fetchMessages(existingConversation.id);
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
        data: {
          'participant_ids': [currentUserId, recipientId],
        },
        options: Options(headers: {'Api-Token': '{{api_token}}'}),
      );

      if (response['statusCode'] == 200 && response.containsKey('data')) {
        final newConversation = Conversation.fromJson(response['data'] as Map<String, dynamic>);
        _allConversations.add(newConversation);
        _currentConversationId = newConversation.id;
        _currentRecipientId = recipientId;
        _currentMessages = [];
        
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
      } else {
        setError(response['message'] ?? 'Failed to create conversation');
      }
    } catch (e) {
      setError('Error starting conversation: $e');
    }
  }

  Future<void> setCurrentConversation(String currentUserId, String recipientId) async {
    final conversation = _allConversations.firstWhere(
      (conv) => conv.participants.any((user) => user.id == currentUserId) &&
                conv.participants.any((user) => user.id == recipientId),
      orElse: () => Conversation(id: '', participants: [], messages: []),
    );

    if (conversation.id.isNotEmpty) {
      _currentConversationId = conversation.id;
      _currentRecipientId = recipientId;
      await _fetchMessages(conversation.id);
      _subscribeToMessages(conversation.id);
      notifyListeners();
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
        _currentMessages = (response['data'] as List<dynamic>)
            .map((json) => Message.fromJson(json as Map<String, dynamic>))
            .toList();
        setSuccess();
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
        (conv) => conv.participants.any((user) => user.id == senderId) &&
                  conv.participants.any((user) => user.id == receiverId),
        orElse: () => Conversation(id: '', participants: [], messages: []),
      );

      String targetConversationId = conversation.id.isNotEmpty ? conversation.id : _currentConversationId;
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
          final newConversation = Conversation.fromJson(response['data'] as Map<String, dynamic>);
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

      final formData = FormData.fromMap({
        'message': content,
        if (mediaFilePath != null) 'media': await MultipartFile.fromFile(mediaFilePath),
      });

      final response = await _apiService.post(
        '/chats/$targetConversationId/messages',
        data: formData,
        options: Options(headers: {'Api-Token': '{{api_token}}'}),
      );

      if (response['statusCode'] == 200 && response.containsKey('data')) {
        final newMessage = Message.fromJson(response['data'] as Map<String, dynamic>);
        _currentMessages.add(newMessage);

        // Update conversation in allConversations
        final convIndex = _allConversations.indexWhere((conv) => conv.id == targetConversationId);
        if (convIndex != -1) {
          final updatedMessages = [newMessage, ..._allConversations[convIndex].messages];
          _allConversations[convIndex] = Conversation(
            id: _allConversations[convIndex].id,
            participants: _allConversations[convIndex].participants,
            messages: updatedMessages,
          );
        } else {
          _allConversations.add(Conversation(
            id: targetConversationId,
            participants: [
              ChatUser(id: senderId, name: '', avatar: null),
              ChatUser(id: receiverId, name: '', avatar: null),
            ],
            messages: [newMessage],
          ));
        }

        setSuccess();
        notifyListeners();
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

  void _subscribeToMessages(String conversationId) {
    final channelName = 'chat.$conversationId';
    _pusherService.subscribeToChannel(channelName).then((channel) {
      if (channel != null) {
        _pusherService.bindToEvent(channelName, 'message.sent', (eventDataString) {
          try {
            final Map<String, dynamic> eventData = jsonDecode(eventDataString) as Map<String, dynamic>;
            final newMessage = Message.fromJson(eventData);
            if (_currentConversationId == conversationId) {
              _currentMessages.add(newMessage);
            }

            final convIndex = _allConversations.indexWhere((conv) => conv.id == conversationId);
            if (convIndex != -1) {
              final updatedMessages = [newMessage, ..._allConversations[convIndex].messages];
              _allConversations[convIndex] = Conversation(
                id: _allConversations[convIndex].id,
                participants: _allConversations[convIndex].participants,
                messages: updatedMessages,
              );
            }
            notifyListeners();
          } catch (e) {
            print('Error processing message.sent event: $e');
          }
        });
      }
    });
  }
}