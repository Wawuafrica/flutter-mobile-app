// Defines the data structures for comments and user information related to social interactions.

/// Represents a user who creates a comment.
class CommentUser {
  final String? id; // This is the numeric ID as a string
  final String? uuid; // ADDED: The user's unique identifier string
  final String name;
  final String? profileImage;

  CommentUser({
    this.id,
    this.uuid, // ADDED
    required this.name,
    this.profileImage,
  });

  factory CommentUser.fromJson(Map<String, dynamic> json) {
    return CommentUser(
      id: json['id']?.toString(),
      uuid: json['uuid'] as String?, // ADDED
      name: json['name'] as String? ?? 'Anonymous',
      profileImage: json['profileImage'] as String?,
    );
  }
}

/// Represents a single comment, which can be a top-level comment or a reply.
class Comment {
  final int id;
  int? parentCommentId;
  String comment;
  final DateTime createdAt;
  final CommentUser user;
  final List<Comment> replies;

  Comment({
    required this.id,
    this.parentCommentId,
    required this.comment,
    required this.createdAt,
    required this.user,
    required this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    var rawReplies = json['replies'] as List<dynamic>? ?? [];
    List<Comment> replyList =
        rawReplies.map((replyJson) => Comment.fromJson(replyJson)).toList();

    return Comment(
      id: json['id'] as int,
      parentCommentId: json['parent_comment_id'] as int?,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: CommentUser.fromJson(json['user'] as Map<String, dynamic>),
      replies: replyList,
    );
  }
}