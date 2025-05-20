class Comment {
  final String id;
  final String
  entityId; // ID of the entity being commented on (e.g., blog post ID, product ID)
  final String entityType; // Type of the entity (e.g., 'blog_post', 'product')
  final String userId;
  final String content;
  final String? parentCommentId; // For threaded comments
  final DateTime createdAt;
  final DateTime? updatedAt;
  // Add fields for user details if not just using userId to fetch them
  // final User? author; // Example: if author details are embedded

  Comment({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.userId,
    required this.content,
    this.parentCommentId,
    required this.createdAt,
    this.updatedAt,
    // this.author,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      entityId: json['entity_id'] as String,
      entityType: json['entity_type'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      parentCommentId: json['parent_comment_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      // author: json['author'] != null ? User.fromJson(json['author']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_id': entityId,
      'entity_type': entityType,
      'user_id': userId,
      'content': content,
      'parent_comment_id': parentCommentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // 'author': author?.toJson(),
    };
  }
}

// If User model is needed and not imported, a placeholder or import is required.
// For now, assuming User model will be imported where Comment is used.
