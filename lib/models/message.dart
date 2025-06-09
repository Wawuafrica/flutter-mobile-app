class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;
  final String? attachmentType;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
    this.attachmentType,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['uuid'] as String,
      senderId:
          json['user'] != null
              ? json['user']['uuid'] as String
              : '', // Handle case where user is null
      receiverId:
          json['chat'] != null
              ? json['chat']['uuid'] as String
              : '', // Handle case where chat is null - for lastMessage this might not exist
      content: json['message'] as String,
      timestamp: DateTime.parse(json['created_at'] as String),
      isRead:
          json['sent_by_me'] as bool? ??
          false, // Use sent_by_me or default to false
      attachmentUrl:
          json['media'] != null && (json['media'] as List).isNotEmpty
              ? json['media'][0]['link'] as String?
              : null,
      attachmentType:
          json['media'] != null && (json['media'] as List).isNotEmpty
              ? (json['media'][0]['name'] as String).contains('image')
                  ? 'image'
                  : 'audio'
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': id,
      'user': {'uuid': senderId},
      'chat': {'uuid': receiverId},
      'message': content,
      'created_at': timestamp.toIso8601String(),
      'sent_by_me': isRead,
      'media':
          attachmentUrl != null
              ? [
                {
                  'name':
                      attachmentType == 'image' ? 'chat image' : 'voice note',
                  'link': attachmentUrl,
                },
              ]
              : [],
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    String? attachmentUrl,
    String? attachmentType,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
    );
  }
}
