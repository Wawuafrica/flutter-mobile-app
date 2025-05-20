import 'message.dart'; // Assuming message.dart exists for the lastMessage field
// import 'user.dart'; // Assuming user.dart exists for participant details

class Conversation {
  final String id;
  final List<String> participantIds; // List of user IDs in the conversation
  // final List<User> participants; // Alternatively, a list of User objects if details are embedded
  final Message? lastMessage; // The last message sent in the conversation
  final DateTime createdAt;
  final DateTime updatedAt;
  final int
  unreadCount; // Unread message count for the current user in this conversation
  final String? title; // Optional: for group chats or custom titles
  final String? type; // e.g., 'one_on_one', 'group'

  Conversation({
    required this.id,
    required this.participantIds,
    // required this.participants,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
    this.title,
    this.type,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      participantIds: List<String>.from(
        json['participant_ids']?.map((x) => x as String) ?? [],
      ),
      // participants: List<User>.from(json['participants']?.map((x) => User.fromJson(x)) ?? []),
      lastMessage:
          json['last_message'] != null
              ? Message.fromJson(json['last_message'] as Map<String, dynamic>)
              : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      unreadCount: json['unread_count'] as int? ?? 0,
      title: json['title'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant_ids': participantIds,
      // 'participants': participants.map((x) => x.toJson()).toList(),
      'last_message': lastMessage?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'unread_count': unreadCount,
      'title': title,
      'type': type,
    };
  }
}
