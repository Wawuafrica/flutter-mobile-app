class NotificationSetting {
  final String
  userId; // To ensure settings are user-specific if GET /notifications/settings is user-scoped
  final bool newMessages;
  final bool gigUpdates;
  final bool productUpdates;
  final bool newBlogPosts;
  final bool generalAnnouncements;
  // Add more specific settings as needed based on API response

  NotificationSetting({
    required this.userId,
    this.newMessages = true,
    this.gigUpdates = true,
    this.productUpdates = true,
    this.newBlogPosts = true,
    this.generalAnnouncements = true,
  });

  factory NotificationSetting.fromJson(Map<String, dynamic> json) {
    return NotificationSetting(
      userId:
          json['user_id'] as String, // Assuming API returns user_id for clarity
      newMessages: json['new_messages'] as bool? ?? true,
      gigUpdates: json['gig_updates'] as bool? ?? true,
      productUpdates: json['product_updates'] as bool? ?? true,
      newBlogPosts: json['new_blog_posts'] as bool? ?? true,
      generalAnnouncements: json['general_announcements'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'new_messages': newMessages,
      'gig_updates': gigUpdates,
      'product_updates': productUpdates,
      'new_blog_posts': newBlogPosts,
      'general_announcements': generalAnnouncements,
    };
  }
}
