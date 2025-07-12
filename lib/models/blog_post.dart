class BlogPost {
  final String uuid;
  final String title;
  final String content;
  final String page;
  final String category;
  final String? categoryId;
  final String status;
  final BlogUser user;
  final BlogImage? coverImage;
  final int likes;
  final List<BlogLiker> likers;
  final List<BlogComment> comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  BlogPost({
    required this.uuid,
    required this.title,
    required this.content,
    required this.page,
    required this.category,
    this.categoryId,
    required this.status,
    required this.user,
    this.coverImage,
    this.likes = 0,
    this.likers = const [],
    this.comments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    try {
      return BlogPost(
        uuid: json['uuid']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        page: json['page']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        categoryId: json['categoryId']?.toString(),
        status: json['status']?.toString() ?? 'Draft',
        user: BlogUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
        coverImage:
            json['coverImage'] != null
                ? BlogImage.fromJson(json['coverImage'] as Map<String, dynamic>)
                : null,
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        likers: _parseLikers(json['likers']),
        comments: _parseComments(json['comments']),
        createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
      );
    } catch (e) {
      // Return a safe default object instead of crashing
      return BlogPost(
        uuid: '',
        title: 'Error Loading Post',
        content: 'Could not load post content',
        page: 'Home',
        category: 'General',
        status: 'Draft',
        user: BlogUser.defaultUser(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  static List<BlogLiker> _parseLikers(dynamic likersRaw) {
    if (likersRaw == null || likersRaw is! List) return [];

    return likersRaw
        .where((e) => e != null)
        .map((e) => BlogLiker.fromJson(e))
        .where((liker) => liker.uuid.isNotEmpty)
        .toList();
  }

  static List<BlogComment> _parseComments(dynamic commentsRaw) {
    if (commentsRaw == null || commentsRaw is! List) return [];

    return commentsRaw
        .where((e) => e != null && e is Map<String, dynamic>)
        .map((e) => BlogComment.fromJson(e as Map<String, dynamic>, ''))
        .toList();
  }

  static DateTime? _parseDateTime(dynamic dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr.toString());
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'title': title,
      'content': content,
      'page': page,
      'category': category,
      'categoryId': categoryId,
      'status': status,
      'user': user.toJson(),
      'coverImage': coverImage?.toJson(),
      'likes': likes,
      'likers': likers.map((e) => e.toJson()).toList(),
      'comments': comments.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BlogPost copyWith({
    String? uuid,
    String? title,
    String? content,
    String? page,
    String? category,
    String? categoryId,
    String? status,
    BlogUser? user,
    BlogImage? coverImage,
    int? likes,
    List<BlogLiker>? likers,
    List<BlogComment>? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BlogPost(
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      content: content ?? this.content,
      page: page ?? this.page,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      user: user ?? this.user,
      coverImage: coverImage ?? this.coverImage,
      likes: likes ?? this.likes,
      likers: likers ?? this.likers,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isLikedByCurrentUser {
    return false;
  }

  String get authorName =>
      '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
  String? get authorAvatar => user.profilePicture;
  String get formattedDate =>
      '${createdAt.day}/${createdAt.month}/${createdAt.year}';
}

class BlogUser {
  final String? uuid;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? profilePicture;

  BlogUser({
    this.uuid,
    this.firstName,
    this.lastName,
    this.email,
    this.profilePicture,
  });

  factory BlogUser.fromJson(Map<String, dynamic> json) {
    String? profilePicture;
    if (json['profilePicture'] != null) {
      if (json['profilePicture'] is String) {
        profilePicture = json['profilePicture'];
      } else if (json['profilePicture'] is Map<String, dynamic>) {
        profilePicture = json['profilePicture']['link'] as String?;
      }
    }

    return BlogUser(
      uuid: json['uuid']?.toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      email: json['email']?.toString(),
      profilePicture: profilePicture,
    );
  }

  // Factory for creating a default user when parsing fails
  factory BlogUser.defaultUser() {
    return BlogUser(
      uuid: null,
      firstName: 'Unknown',
      lastName: 'User',
      email: null,
      profilePicture: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'profilePicture': profilePicture,
    };
  }
}

class BlogImage {
  final String name;
  final String link;

  BlogImage({required this.name, required this.link});

  factory BlogImage.fromJson(Map<String, dynamic> json) {
    return BlogImage(
      name: json['name']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'link': link};
  }
}

class BlogLiker {
  final String name;
  final String uuid;
  final String email;
  final String? profilePicture;

  BlogLiker({
    required this.name,
    required this.uuid,
    required this.email,
    this.profilePicture,
  });

  factory BlogLiker.fromJson(dynamic json) {
    if (json == null) {
      return BlogLiker(name: '', uuid: '', email: '', profilePicture: null);
    }

    if (json is Map<String, dynamic>) {
      String? profilePicture;
      if (json['profilePicture'] != null) {
        if (json['profilePicture'] is String) {
          profilePicture = json['profilePicture'];
        } else if (json['profilePicture'] is Map<String, dynamic>) {
          profilePicture = json['profilePicture']['link'] as String?;
        }
      }

      return BlogLiker(
        name: json['name']?.toString() ?? '',
        uuid: json['uuid']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        profilePicture: profilePicture,
      );
    } else if (json is String) {
      // If backend returns just a user ID string
      return BlogLiker(name: '', uuid: json, email: '', profilePicture: null);
    } else {
      return BlogLiker(name: '', uuid: '', email: '', profilePicture: null);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'uuid': uuid,
      'email': email,
      'profilePicture': profilePicture,
    };
  }
}

class BlogComment {
  final int id;
  final String content;
  final DateTime createdAt;
  final BlogUser commentedBy;
  bool isLiked;
  final List<BlogLiker> likers;
  final List<BlogComment> subComments;

  BlogComment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.commentedBy,
    this.isLiked = false,
    this.likers = const [],
    this.subComments = const [],
  });

  factory BlogComment.fromJson(
    Map<String, dynamic> json,
    String currentUserId,
  ) {
    try {
      // Parse likers safely - handle null case
      final likersRaw = json['likers'];
      List<BlogLiker> likers = [];
      if (likersRaw is List) {
        likers =
            likersRaw
                .where((e) => e != null)
                .map((e) => BlogLiker.fromJson(e))
                .where((l) => l.uuid.isNotEmpty)
                .toList();
      }
      // If likersRaw is null, likers remains empty list

      // Parse subComments safely - handle null case
      final subCommentsRaw = json['subComments'];
      List<BlogComment> subComments = [];
      if (subCommentsRaw is List) {
        subComments =
            subCommentsRaw
                .where((e) => e != null && e is Map<String, dynamic>)
                .map(
                  (e) => BlogComment.fromJson(
                    e as Map<String, dynamic>,
                    currentUserId,
                  ),
                )
                .toList();
      }
      // If subCommentsRaw is null, subComments remains empty list

      // Handle isLiked safely
      bool isLiked = false;
      if (json['isLiked'] != null) {
        isLiked = json['isLiked'] is bool ? json['isLiked'] : false;
      } else {
        isLiked = likers.any((liker) => liker.uuid == currentUserId);
      }

      // Parse DateTime safely
      DateTime createdAt;
      try {
        createdAt = DateTime.parse(json['createdAt']?.toString() ?? '');
      } catch (e) {
        createdAt = DateTime.now();
      }

      return BlogComment(
        id: (json['id'] as num?)?.toInt() ?? 0,
        content: json['content']?.toString() ?? '',
        createdAt: createdAt,
        commentedBy: BlogUser.fromJson(
          json['commentedBy'] as Map<String, dynamic>? ?? {},
        ),
        isLiked: isLiked,
        likers: likers,
        subComments: subComments,
      );
    } catch (e) {
      // Return a safe default comment if parsing fails
      return BlogComment(
        id: 0,
        content: 'Error loading comment',
        createdAt: DateTime.now(),
        commentedBy: BlogUser.defaultUser(),
        isLiked: false,
        likers: [],
        subComments: [],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'commentedBy': commentedBy.toJson(),
      'isLiked': isLiked,
      'likers': likers.map((e) => e.toJson()).toList(),
      'subComments': subComments.map((e) => e.toJson()).toList(),
    };
  }

  BlogComment copyWith({
    int? id,
    String? content,
    DateTime? createdAt,
    BlogUser? commentedBy,
    bool? isLiked,
    List<BlogLiker>? likers,
    List<BlogComment>? subComments,
  }) {
    return BlogComment(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      commentedBy: commentedBy ?? this.commentedBy,
      isLiked: isLiked ?? this.isLiked,
      likers: likers ?? this.likers,
      subComments: subComments ?? this.subComments,
    );
  }
}
