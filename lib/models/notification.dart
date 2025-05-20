class Notification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type; // e.g., 'message', 'system', 'gig'
  final Map<String, dynamic>
  data; // Additional data specific to notification type

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    Map<String, dynamic>? data,
  }) : data = data ?? {};

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool? ?? false,
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'type': type,
      'data': data,
    };
  }

  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? type,
    Map<String, dynamic>? data,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      data: data ?? this.data,
    );
  }

  Notification markAsRead() {
    return copyWith(isRead: true);
  }
}
