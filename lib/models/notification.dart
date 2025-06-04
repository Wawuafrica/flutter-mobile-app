class NotificationModel {
  final String id;
  final String type;
  final String notifiableType;
  final int notifiableId;
  final Map<String, dynamic> data;
  final String? readAt;
  final String createdAt;
  final String updatedAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.notifiableType,
    required this.notifiableId,
    required this.data,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      notifiableType: json['notifiable_type'] as String? ?? '',
      notifiableId: json['notifiable_id'] as int? ?? 0,
      data: (json['data'] as Map<String, dynamic>?)?.cast<String, dynamic>() ?? {},
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  bool get isRead => readAt != null;

  DateTime get timestamp {
    try {
      return DateTime.parse(createdAt);
    } catch (e) {
      // debugPrint('Invalid timestamp format for createdAt: $createdAt');
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  NotificationModel markAsRead() {
    return NotificationModel(
      id: id,
      type: type,
      notifiableType: notifiableType,
      notifiableId: notifiableId,
      data: data,
      readAt: DateTime.now().toIso8601String(),
      createdAt: createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }
}