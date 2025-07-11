import 'chat_user.dart';
import 'message.dart';

class Conversation {
  final String id;
  final List<ChatUser> participants;
  final Message? lastMessage;
  final List<Message> messages;
  final String? name; // Added this field since it's in your API response

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.messages = const [],
    this.name,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['uuid'] as String,
      participants:
          (json['participants'] as List<dynamic>).map((user) {
            // Add debugging for each user
            print('Processing user: $user');
            return ChatUser.fromJson(user as Map<String, dynamic>);
          }).toList(),
      // Handle both snake_case and camelCase for lastMessage
      lastMessage:
          (json['last_message'] ?? json['lastMessage']) != null
              ? Message.fromJson(
                (json['last_message'] ?? json['lastMessage'])
                    as Map<String, dynamic>,
              )
              : null,
      messages: [], // Messages are fetched separately
      name: json['name'] as String?, // Added name field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': id,
      'participants': participants.map((user) => user.toJson()).toList(),
      'last_message': lastMessage?.toJson(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'name': name,
    };
  }

  // Add the copyWith method here
  Conversation copyWith({
    String? id,
    List<ChatUser>? participants,
    Message? lastMessage,
    List<Message>? messages,
    String? name,
  }) {
    return Conversation(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      messages: messages ?? this.messages,
      name: name ?? this.name,
    );
  }
}
