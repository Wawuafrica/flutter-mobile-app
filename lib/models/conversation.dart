import 'chat_user.dart';
import 'message.dart';

class Conversation {
  final String id;
  final List<ChatUser> participants;
  final Message? lastMessage;
  final List<Message> messages;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.messages = const [],
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['uuid'] as String,
      participants: (json['participants'] as List<dynamic>)
          .map((user) => ChatUser.fromJson(user as Map<String, dynamic>))
          .toList(),
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      messages: [], // Messages are fetched separately
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': id,
      'participants': participants.map((user) => user.toJson()).toList(),
      'last_message': lastMessage?.toJson(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };
  }
}