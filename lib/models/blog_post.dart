class BlogPost {
  final String uuid;
  final String title;
  final String content;
  final String page;
  final String category;
  final String status;
  final BlogUser user;
  final BlogImage coverImage;
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
    required this.status,
    required this.user,
    required this.coverImage,
    this.likes = 0,
    this.likers = const [],
    this.comments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    // Defensive parsing and error logging
    try {
      if (json['user'] is! Map<String, dynamic>) {
        print('[BlogPost.fromJson] ERROR: user field is not a Map. Value: \\${json['user']}');
        throw Exception('Expected user to be Map<String, dynamic>, got: \\${json['user'].runtimeType}');
      }
      if (json['coverImage'] is! Map<String, dynamic>) {
        print('[BlogPost.fromJson] ERROR: coverImage field is not a Map. Value: \\${json['coverImage']}');
        throw Exception('Expected coverImage to be Map<String, dynamic>, got: \\${json['coverImage'].runtimeType}');
      }
      if (json['comments'] != null && json['comments'] is! List) {
        print('[BlogPost.fromJson] ERROR: comments field is not a List. Value: \\${json['comments']}');
        throw Exception('Expected comments to be List, got: \\${json['comments'].runtimeType}');
      }
      if (json['likers'] != null && json['likers'] is! List) {
        print('[BlogPost.fromJson] ERROR: likers field is not a List. Value: \\${json['likers']}');
        throw Exception('Expected likers to be List, got: \\${json['likers'].runtimeType}');
      }
      return BlogPost(
        uuid: json['uuid'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        page: json['page'] as String,
        category: json['category'] as String,
        status: json['status'] as String,
        user: BlogUser.fromJson(json['user'] as Map<String, dynamic>),
        coverImage: BlogImage.fromJson(
          json['coverImage'] as Map<String, dynamic>,
        ),
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        likers: () {
          final likersRaw = json['likers'];
          if (likersRaw is List) {
            return likersRaw.map((e) => BlogLiker.fromJson(e)).where((liker) => liker.uuid.isNotEmpty).toList();
          }
          return <BlogLiker>[];
        }(),
        comments: () {
          final commentsRaw = json['comments'];
          if (commentsRaw is List) {
            return commentsRaw.map((e) => BlogComment.fromJson(e as Map<String, dynamic>, '')).toList();
          }
          return <BlogComment>[];
        }(),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
    } catch (e, stack) {
      print('[BlogPost.fromJson] Parsing error: $e\nStack: $stack\nInput: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'title': title,
      'content': content,
      'page': page,
      'category': category,
      'status': status,
      'user': user.toJson(),
      'coverImage': coverImage.toJson(),
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
    // TODO: Implement current user check
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
  final String email;
  final String? profilePicture;

  BlogUser({
    this.uuid,
    this.firstName,
    this.lastName,
    required this.email,
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
      uuid: json['uuid'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      profilePicture: profilePicture,
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
      name: json['name'] as String,
      link: json['link'] as String,
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
        name: json['name'] as String? ?? '',
        uuid: json['uuid'] as String? ?? '',
        email: json['email'] as String? ?? '',
        profilePicture: profilePicture,
      );
    } else if (json is String) {
      // If backend returns just a user ID string
      print('[BlogLiker.fromJson] WARNING: Got String instead of Map. Value: $json');
      return BlogLiker(name: '', uuid: json, email: '', profilePicture: null);
    } else {
      print('[BlogLiker.fromJson] ERROR: Unexpected type: ${json.runtimeType}, value: $json');
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
      // Defensive: likers can be null, missing, or a list
      final likersRaw = json['likers'];
      List<BlogLiker> likers = [];
      if (likersRaw is List) {
        likers = likersRaw.map((e) => BlogLiker.fromJson(e)).where((l) => l.uuid.isNotEmpty).toList();
      }

      // Defensive: subComments can be null, missing, or a list
      final subCommentsRaw = json['subComments'];
      List<BlogComment> subComments = [];
      if (subCommentsRaw is List) {
        subComments = subCommentsRaw.map((e) => BlogComment.fromJson(e as Map<String, dynamic>, currentUserId)).toList();
      }

      // isLiked may be provided by backend, otherwise fallback to likers
      bool isLiked = false;
      if (json['isLiked'] != null) {
        isLiked = json['isLiked'] is bool ? json['isLiked'] : false;
      } else {
        isLiked = likers.any((liker) => liker.uuid == currentUserId);
      }
      return BlogComment(
        id: json['id'] as int,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        commentedBy: BlogUser.fromJson(json['commentedBy'] as Map<String, dynamic>),
        isLiked: isLiked,
        likers: likers,
        subComments: subComments,
      );
    } catch (e, stack) {
      print('[BlogComment.fromJson] Parsing error: $e\nStack: $stack\nInput: $json');
      rethrow;
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
