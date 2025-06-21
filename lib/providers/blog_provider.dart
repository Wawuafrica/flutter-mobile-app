import '../models/blog_post.dart';
import '../services/api_service.dart';
import '../services/pusher_service.dart';
import 'base_provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'dart:convert';
import 'package:logger/logger.dart';

/// BlogProvider manages the state of blog posts with real-time updates.
///
/// This provider handles:
/// - Fetching blog posts with pagination
/// - Fetching single post details
/// - Liking/unliking posts
/// - Adding comments and sub-comments
/// - Liking comments
/// - Real-time updates via Pusher
class BlogProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;
  final Logger _logger = Logger();

  List<BlogPost> _posts = [];
  BlogPost? _selectedPost;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _pusherEventsInitialized = false;

  // Getters
  List<BlogPost> get posts => _posts;
  BlogPost? get selectedPost => _selectedPost;
  @override
  bool get isLoading => _isLoading;
  @override
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  BlogProvider({
    required ApiService apiService,
    required PusherService pusherService,
  }) : _apiService = apiService,
       _pusherService = pusherService {
    _initializePusherEvents();
  }

  /// Initialize Pusher event listeners for blog posts
  void _initializePusherEvents() {
    if (_pusherEventsInitialized || !_pusherService.isInitialized) {
      return;
    }

    _logger.i('BlogProvider: Initializing Pusher events for blog posts');

    // Listen for new posts created
    _pusherService.bindToEvent('posts', 'post.created', _handlePostCreated);

    // Listen for post updates
    _pusherService.bindToEvent('posts', 'post.updated', _handlePostUpdated);

    // Listen for post deletions
    _pusherService.bindToEvent('posts', 'post.deleted', _handlePostDeleted);

    // Listen for post likes
    _pusherService.bindToEvent('posts', 'post.liked', _handlePostLiked);

    // Listen for post comments
    _pusherService.bindToEvent('posts', 'post.comment', _handlePostComment);

    // Listen for comment likes
    _pusherService.bindToEvent(
      'posts',
      'post.comment.like',
      _handleCommentLike,
    );

    _pusherEventsInitialized = true;
    _logger.d('BlogProvider: Pusher events initialized successfully');
  }

  /// Handle new post created event
  void _handlePostCreated(PusherEvent event) {
    try {
      _logger.i('BlogProvider: Received post.created event');
      final eventData = jsonDecode(event.data) as Map<String, dynamic>;
      final newPost = BlogPost.fromJson(
        eventData['post'] as Map<String, dynamic>,
      );

      // Prevent duplicate posts: only add if not already present
      if (!_posts.any((post) => post.uuid == newPost.uuid)) {
        _posts.insert(0, newPost);
      }
      notifyListeners();

      _logger.d('BlogProvider: New post added: ${newPost.title}');
    } catch (e) {
      _logger.e('BlogProvider: Error handling post.created event: $e');
    }
  }

  /// Handle post updated event
  void _handlePostUpdated(PusherEvent event) {
    try {
      _logger.i('BlogProvider: Received post.updated event');
      final eventData = jsonDecode(event.data) as Map<String, dynamic>;
      final updatedPost = BlogPost.fromJson(
        eventData['post'] as Map<String, dynamic>,
      );

      // Update post in the list
      final postIndex = _posts.indexWhere(
        (post) => post.uuid == updatedPost.uuid,
      );
      if (postIndex != -1) {
        _posts[postIndex] = updatedPost;
      }

      // Update selected post if it's the one being updated
      if (_selectedPost?.uuid == updatedPost.uuid) {
        _selectedPost = updatedPost;
      }

      notifyListeners();
      _logger.d('BlogProvider: Post updated: ${updatedPost.title}');
    } catch (e) {
      _logger.e('BlogProvider: Error handling post.updated event: $e');
    }
  }

  /// Handle post deleted event
  void _handlePostDeleted(PusherEvent event) {
    try {
      _logger.i('BlogProvider: Received post.deleted event');
      final eventData = jsonDecode(event.data) as Map<String, dynamic>;
      final deletedPostUuid = eventData['post_uuid'] as String;

      // Remove post from the list
      _posts.removeWhere((post) => post.uuid == deletedPostUuid);

      // Clear selected post if it's the one being deleted
      if (_selectedPost?.uuid == deletedPostUuid) {
        _selectedPost = null;
      }

      notifyListeners();
      _logger.d('BlogProvider: Post deleted: $deletedPostUuid');
    } catch (e) {
      _logger.e('BlogProvider: Error handling post.deleted event: $e');
    }
  }

  /// Handle post liked event
  void _handlePostLiked(PusherEvent event) {
    try {
      _logger.i('BlogProvider: Received post.liked event');
      final eventData = jsonDecode(event.data) as Map<String, dynamic>;
      final updatedPost = BlogPost.fromJson(
        eventData['post'] as Map<String, dynamic>,
      );

      // Update post in the list
      final postIndex = _posts.indexWhere(
        (post) => post.uuid == updatedPost.uuid,
      );
      if (postIndex != -1) {
        _posts[postIndex] = updatedPost;
      }

      // Update selected post if it's the one being liked
      if (_selectedPost?.uuid == updatedPost.uuid) {
        _selectedPost = updatedPost;
      }

      notifyListeners();
      _logger.d('BlogProvider: Post like updated: ${updatedPost.title}');
    } catch (e) {
      _logger.e('BlogProvider: Error handling post.liked event: $e');
    }
  }

  /// Handle post comment event
  void _handlePostComment(PusherEvent event) {
    try {
      _logger.i('BlogProvider: Received post.comment event');
      final eventData = jsonDecode(event.data) as Map<String, dynamic>;
      final updatedPost = BlogPost.fromJson(
        eventData['post'] as Map<String, dynamic>,
      );

      // Update post in the list
      final postIndex = _posts.indexWhere(
        (post) => post.uuid == updatedPost.uuid,
      );
      if (postIndex != -1) {
        _posts[postIndex] = updatedPost;
      }

      // Update selected post if it's the one receiving the comment
      if (_selectedPost?.uuid == updatedPost.uuid) {
        _selectedPost = updatedPost;
      }

      notifyListeners();
      _logger.d('BlogProvider: Post comment added: ${updatedPost.title}');
    } catch (e) {
      _logger.e('BlogProvider: Error handling post.comment event: $e');
    }
  }

  /// Handle comment like event
  void _handleCommentLike(PusherEvent event) {
    try {
      _logger.i('BlogProvider: Received post.comment.like event');
      final eventData = jsonDecode(event.data) as Map<String, dynamic>;
      final updatedPost = BlogPost.fromJson(
        eventData['post'] as Map<String, dynamic>,
      );

      // Update post in the list
      final postIndex = _posts.indexWhere(
        (post) => post.uuid == updatedPost.uuid,
      );
      if (postIndex != -1) {
        _posts[postIndex] = updatedPost;
      }

      // Update selected post if it's the one with the liked comment
      if (_selectedPost?.uuid == updatedPost.uuid) {
        _selectedPost = updatedPost;
      }

      notifyListeners();
      _logger.d('BlogProvider: Comment like updated: ${updatedPost.title}');
    } catch (e) {
      _logger.e('BlogProvider: Error handling post.comment.like event: $e');
    }
  }

  /// Subscribe to post-specific events when viewing a specific post
  void subscribeToPostEvents(String postUuid) {
    if (!_pusherService.isInitialized) {
      _logger.w(
        'BlogProvider: PusherService not initialized, cannot subscribe to post events',
      );
      return;
    }

    _logger.i('BlogProvider: Subscribing to events for post: $postUuid');

    // Subscribe to post-specific channels for real-time updates
    _pusherService.subscribeToChannel('post.updated.$postUuid');
    _pusherService.subscribeToChannel('post.comment.$postUuid');
    _pusherService.subscribeToChannel('post.liked.$postUuid');
    _pusherService.subscribeToChannel('post.comment.like.$postUuid');

    // Bind to post-specific events
    _pusherService.bindToEvent(
      'post.updated.$postUuid',
      'post.updated',
      _handlePostUpdated,
    );
    _pusherService.bindToEvent(
      'post.comment.$postUuid',
      'post.comment',
      _handlePostComment,
    );
    _pusherService.bindToEvent(
      'post.liked.$postUuid',
      'post.liked',
      _handlePostLiked,
    );
    _pusherService.bindToEvent(
      'post.comment.like.$postUuid',
      'post.comment.like',
      _handleCommentLike,
    );
  }

  /// Unsubscribe from post-specific events
  void unsubscribeFromPostEvents(String postUuid) {
    if (!_pusherService.isInitialized) {
      return;
    }

    _logger.i('BlogProvider: Unsubscribing from events for post: $postUuid');

    _pusherService.unsubscribeFromChannel('post.updated.$postUuid');
    _pusherService.unsubscribeFromChannel('post.comment.$postUuid');
    _pusherService.unsubscribeFromChannel('post.liked.$postUuid');
    _pusherService.unsubscribeFromChannel('post.comment.like.$postUuid');
  }

  /// Fetches blog posts with pagination
  Future<void> fetchPosts({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _posts = [];
    } else if (!_hasMore) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get(
        '/posts',
        queryParameters: {'page': _currentPage},
      );
      _logger.d('BlogProvider: Fetch posts response: ${response['data']}');

      if (response['statusCode'] == 200) {
        final List<dynamic> postsData = response['data'] ?? [];
        final newPosts =
            postsData
                .map(
                  (postJson) =>
                      BlogPost.fromJson(postJson as Map<String, dynamic>),
                )
                .toList();

        _hasMore = newPosts.isNotEmpty;
        _currentPage++;
        _posts = refresh ? newPosts : [..._posts, ...newPosts];

        // Initialize Pusher events if not already done and service is ready
        if (!_pusherEventsInitialized && _pusherService.isInitialized) {
          _initializePusherEvents();
        }
      } else {
        _errorMessage = response['message'] ?? 'Failed to load posts';
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch posts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches a single blog post by ID
  Future<BlogPost?> fetchPostById(String postId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/post/$postId');

      if (response['statusCode'] == 200) {
        _selectedPost = BlogPost.fromJson(response['data']);

        // Subscribe to real-time events for this specific post
        subscribeToPostEvents(postId);

        return _selectedPost;
      } else {
        _errorMessage = response['message'] ?? 'Failed to load post';
        return null;
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch post: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle like on a post
  Future<bool> toggleLikePost(String postId) async {
    try {
      final response = await _apiService.post('/post/like/$postId');

      _logger.d('BlogProvider: Post like response: ${response['data']}');
      _logger.d('BlogProvider: Post like response: ${response['statusCode']}');
      if (response['statusCode'] == 200) {
        final updatedPost = BlogPost.fromJson(response['data']);

        // Update the post in the list if it exists
        final postIndex = _posts.indexWhere((post) => post.uuid == postId);
        if (postIndex != -1) {
          _posts[postIndex] = updatedPost;
        }

        _logger.d('BlogProvider: Post like updated: ${updatedPost.title}');

        // Update selected post if it's the one being liked
        if (_selectedPost?.uuid == postId) {
          _selectedPost = updatedPost;
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to like post: $e';
      notifyListeners();
      return false;
    }
  }

  /// Add a comment to a post
  Future<BlogComment?> addComment(String postId, String comment) async {
    try {
      final response = await _apiService.post(
        '/post/comment/$postId',
        data: {'type': 'comment', 'comment': comment},
      );

      if (response['statusCode'] == 200) {
        final updatedPost = BlogPost.fromJson(response['data']);

        // Update selected post if it's the current one
        if (_selectedPost?.uuid == postId) {
          _selectedPost = updatedPost;
        }

        // Update the post in the list if it exists
        final postIndex = _posts.indexWhere((post) => post.uuid == postId);
        if (postIndex != -1) {
          _posts[postIndex] = updatedPost;
        }

        // Find the new comment by comparing with existing comments
        final newComment = updatedPost.comments.lastWhere(
          (c) =>
              !_selectedPost!.comments.any((existing) => existing.id == c.id),
          orElse: () => updatedPost.comments.last,
        );

        notifyListeners();
        return newComment;
      }
      return null;
    } catch (e) {
      _errorMessage = 'Failed to add comment: $e';
      notifyListeners();
      return null;
    }
  }

  /// Add a reply to a comment
  Future<BlogComment?> addReply(
    String postId,
    int commentId,
    String reply,
  ) async {
    try {
      final response = await _apiService.post(
        '/post/comment/$postId',
        data: {'type': 'sub_comment', 'commentId': commentId, 'comment': reply},
      );

      if (response['statusCode'] == 200) {
        final updatedPost = BlogPost.fromJson(response['data']);

        // Update selected post if it's the current one
        if (_selectedPost?.uuid == postId) {
          _selectedPost = updatedPost;
        }

        // Update the post in the list if it exists
        final postIndex = _posts.indexWhere((post) => post.uuid == postId);
        if (postIndex != -1) {
          _posts[postIndex] = updatedPost;
        }

        // Find the new reply by comparing with existing subComments
        final commentIndex = updatedPost.comments.indexWhere(
          (c) => c.id == commentId,
        );
        if (commentIndex != -1) {
          final newReply = updatedPost.comments[commentIndex].subComments
              .lastWhere(
                (sc) =>
                    !_selectedPost!.comments[commentIndex].subComments.any(
                      (existing) => existing.id == sc.id,
                    ),
                orElse:
                    () => updatedPost.comments[commentIndex].subComments.last,
              );

          notifyListeners();
          return newReply;
        }
      }
      return null;
    } catch (e) {
      _errorMessage = 'Failed to add reply: $e';
      notifyListeners();
      return null;
    }
  }

  /// Toggle like on a comment
  Future<bool> toggleLikeComment(String postId, int commentId) async {
    try {
      final response = await _apiService.post(
        '/post/comment/like/',
        data: {'postId': postId, 'commentId': commentId},
      );

      if (response['statusCode'] == 200) {
        final updatedPost = BlogPost.fromJson(response['data']);

        // Update selected post if it's the current one
        if (_selectedPost?.uuid == postId) {
          _selectedPost = updatedPost;
        }

        // Update the post in the list if it exists
        final postIndex = _posts.indexWhere((post) => post.uuid == postId);
        if (postIndex != -1) {
          _posts[postIndex] = updatedPost;
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to like comment: $e';
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void selectPost(BlogPost post) {
    // Unsubscribe from previous post events if any
    if (_selectedPost != null) {
      unsubscribeFromPostEvents(_selectedPost!.uuid);
    }

    _selectedPost = post;

    // Subscribe to new post events
    subscribeToPostEvents(post.uuid);

    setSuccess();
  }

  // Refresh the provider state
  void refresh() {
    // Unsubscribe from current post events if any
    if (_selectedPost != null) {
      unsubscribeFromPostEvents(_selectedPost!.uuid);
    }

    _posts = [];
    _selectedPost = null;
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Unsubscribe from all post-specific events
    if (_selectedPost != null) {
      unsubscribeFromPostEvents(_selectedPost!.uuid);
    }
    super.dispose();
  }
}
