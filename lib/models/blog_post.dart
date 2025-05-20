class BlogPost {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final DateTime publishedAt;
  final List<String> categories;
  final List<String> tags;
  final String? featuredImageUrl;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final bool isFeatured;
  final String status; // 'draft', 'published', 'archived'

  BlogPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.publishedAt,
    required this.categories,
    required this.tags,
    this.featuredImageUrl,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isFeatured = false,
    required this.status,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String,
      authorAvatarUrl: json['author_avatar_url'] as String?,
      publishedAt: DateTime.parse(json['published_at'] as String),
      categories:
          (json['categories'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      featuredImageUrl: json['featured_image_url'] as String?,
      viewCount: json['view_count'] as int? ?? 0,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar_url': authorAvatarUrl,
      'published_at': publishedAt.toIso8601String(),
      'categories': categories,
      'tags': tags,
      'featured_image_url': featuredImageUrl,
      'view_count': viewCount,
      'like_count': likeCount,
      'comment_count': commentCount,
      'is_featured': isFeatured,
      'status': status,
    };
  }

  BlogPost copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    DateTime? publishedAt,
    List<String>? categories,
    List<String>? tags,
    String? featuredImageUrl,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    bool? isFeatured,
    String? status,
  }) {
    return BlogPost(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      featuredImageUrl: featuredImageUrl ?? this.featuredImageUrl,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isFeatured: isFeatured ?? this.isFeatured,
      status: status ?? this.status,
    );
  }

  // Helper methods
  bool isPublished() {
    return status == 'published';
  }

  bool isDraft() {
    return status == 'draft';
  }

  bool isArchived() {
    return status == 'archived';
  }

  String getExcerpt(int maxLength) {
    if (content.length <= maxLength) {
      return content;
    }
    return '${content.substring(0, maxLength)}...';
  }
}
