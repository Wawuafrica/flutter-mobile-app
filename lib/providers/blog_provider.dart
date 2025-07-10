import '../models/blog_post.dart';
import '../services/api_service.dart';
import '../services/pusher_service.dart';
import 'base_provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'dart:async';

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
  StreamSubscription<bool>? _pusherInitSubscription;

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
    _listenToPusherInitialization();
  }

  /// Listen to Pusher initialization state changes
  void _listenToPusherInitialization() {
    _pusherInitSubscription = _pusherService.onInitialized.listen((
      isInitialized,
    ) {
      if (isInitialized && !_pusherEventsInitialized) {
        _logger.i('BlogProvider: Pusher reinitialized, setting up events');
        _initializePusherEvents();
      } else if (!isInitialized) {
        _logger.w(
          'BlogProvider: Pusher disconnected, events will be restored on reconnection',
        );
        _pusherEventsInitialized = false;
      }
    });
  }

  // Improved method to safely parse event data
  Map<String, dynamic> _parseEventData(dynamic eventData) {
    try {
      if (eventData is String) {
        return jsonDecode(eventData) as Map<String, dynamic>;
      } else if (eventData is Map<String, dynamic>) {
        return eventData;
      } else if (eventData is Map) {
        // Handle LinkedMap<Object?, Object?> by converting to Map<String, dynamic>
        return Map<String, dynamic>.from(
          eventData.map((key, value) {
            if (value is Map) {
              return MapEntry(key.toString(), _parseEventData(value));
            } else if (value is List) {
              return MapEntry(
                key.toString(),
                value
                    .map((item) => item is Map ? _parseEventData(item) : item)
                    .toList(),
              );
            }
            return MapEntry(key.toString(), value);
          }),
        );
      }
      throw Exception('Unexpected event data type: ${eventData.runtimeType}');
    } catch (e) {
      _logger.e('Error parsing event data: $e');
      rethrow;
    }
  }

  /// Initialize Pusher event listeners for blog posts
  void _initializePusherEvents() {
    if (_pusherEventsInitialized) {
      _logger.w('BlogProvider: Pusher events already initialized, skipping');
      return;
    }

    if (!_pusherService.isInitialized) {
      _logger.w(
        'BlogProvider: PusherService not initialized, deferring event setup',
      );
      return;
    }

    _logger.i('BlogProvider: Initializing Pusher events for blog posts');

    try {
      // Subscribe to the general posts channel
      _pusherService.subscribeToChannel('posts');

      // Add a small delay to ensure channel subscription is processed
      Timer(const Duration(milliseconds: 100), () {
        // Listen for general events on the posts channel
        _pusherService.bindToEvent('posts', 'post.created', _handlePostCreated);
        _pusherService.bindToEvent('posts', 'post.deleted', _handlePostDeleted);
        _pusherService.bindToEvent('posts', 'post.updated', _handlePostUpdated);
        _pusherService.bindToEvent('posts', 'post.liked', _handlePostLiked);
        _pusherService.bindToEvent('posts', 'post.comment', _handlePostComment);
        _pusherService.bindToEvent(
          'posts',
          'post.comment.like',
          _handleCommentLike,
        );

        _pusherEventsInitialized = true;
        _logger.i('BlogProvider: Pusher events initialized successfully');
      });
    } catch (e) {
      _logger.e('BlogProvider: Error initializing Pusher events: $e');
    }
  }

  /// Ensure event handlers are bound (call this periodically or on network reconnect)
  void _ensureEventHandlers() {
    if (!_pusherService.isInitialized) {
      _logger.w(
        'BlogProvider: Cannot ensure handlers - PusherService not initialized',
      );
      return;
    }

    _logger.d('BlogProvider: Ensuring event handlers are bound');

    // Re-bind all event handlers to ensure they're registered
    _pusherService.bindToEvent('posts', 'post.created', _handlePostCreated);
    _pusherService.bindToEvent('posts', 'post.deleted', _handlePostDeleted);
    _pusherService.bindToEvent('posts', 'post.updated', _handlePostUpdated);
    _pusherService.bindToEvent('posts', 'post.liked', _handlePostLiked);
    _pusherService.bindToEvent('posts', 'post.comment', _handlePostComment);
    _pusherService.bindToEvent(
      'posts',
      'post.comment.like',
      _handleCommentLike,
    );

    // Re-bind post-specific handlers if there's a selected post
    if (_selectedPost != null) {
      _bindPostSpecificHandlers(_selectedPost!.uuid);
    }

    _logger.d('BlogProvider: Event handlers ensured');
  }

  /// Bind post-specific event handlers
  void _bindPostSpecificHandlers(String postUuid) {
    _pusherService.bindToEvent(
      'post.updated.$postUuid',
      'post.updated',
      _handlePostUpdated,
    );
    _pusherService.bindToEvent(
      'post.liked.$postUuid',
      'post.liked',
      _handlePostLiked,
    );
    _pusherService.bindToEvent(
      'post.comment.$postUuid',
      'post.comment',
      _handlePostComment,
    );
    _pusherService.bindToEvent(
      'post.comment.like.$postUuid',
      'post.comment.like',
      _handleCommentLike,
    );
  }

  /// Handle new post created event
  void _handlePostCreated(PusherEvent event) {
    try {
      _logger.i('BlogProvider: Received post.created event: ${event.data}');

      // Parse the event data
      final eventData = _parseEventData(event.data);

      // Log the structure for debugging
      _logger.i(
        'BlogProvider: Parsed event data keys: ${eventData.keys.toList()}',
      );

      // Get the post data, handling case where it might be a JSON string
      dynamic postData = eventData['post'];
      if (postData is String) {
        postData = jsonDecode(postData) as Map<String, dynamic>;
      }
      if (postData == null || postData is! Map<String, dynamic>) {
        throw Exception('Post data is null or invalid in event');
      }

      // Validate required fields before creating BlogPost
      if (postData['user'] == null) {
        throw Exception('User data is null in post');
      }

      if (postData['coverImage'] == null) {
        throw Exception('Cover image data is null in post');
      }

      final newPost = BlogPost.fromJson(postData);

      // Prevent duplicate posts: only add if not already present
      if (!_posts.any((post) => post.uuid == newPost.uuid)) {
        _posts.insert(0, newPost);
        _logger.i(
          'BlogProvider: New post added: ${newPost.title} (UUID: ${newPost.uuid})',
        );
        notifyListeners();
      } else {
        _logger.w(
          'BlogProvider: Duplicate post detected, not adding: ${newPost.title}',
        );
      }
    } catch (e) {
      _logger.e('BlogProvider: Error handling post.created event: $e');
      _errorMessage = 'Failed to process new post: $e';
      notifyListeners();
    }
  }

  /// Handle post updated event
  void _handlePostUpdated(PusherEvent event) {
    try {
      _logger.i('BlogProvider: Received post.updated event: ${event.data}');

      final eventData = _parseEventData(event.data);
      dynamic postData = eventData['post'];
      if (postData is String) {
        postData = jsonDecode(postData) as Map<String, dynamic>;
      }
      if (postData == null || postData is! Map<String, dynamic>) {
        throw Exception('Post data is null or invalid in event');
      }

      final updatedPost = BlogPost.fromJson(postData);

      // Update post in the list
      final postIndex = _posts.indexWhere(
        (post) => post.uuid == updatedPost.uuid,
      );
      if (postIndex != -1) {
        _posts[postIndex] = updatedPost;
        _logger.i('BlogProvider: Post updated: ${updatedPost.title}');
      }

      // Update selected post if it's the one being updated
      if (_selectedPost?.uuid == updatedPost.uuid) {
        _selectedPost = updatedPost;
        _logger.i('BlogProvider: Selected post updated: ${updatedPost.title}');
      }

      notifyListeners();
    } catch (e) {
      _logger.e('BlogProvider: Error handling post.updated event: $e');
      _errorMessage = 'Failed to process post update: $e';
      notifyListeners();
    }
  }

  /// Handle post deleted event
  void _handlePostDeleted(PusherEvent event) {
    try {
      _logger.i('BlogProvider: Received post.deleted event: ${event.data}');

      final eventData = _parseEventData(event.data);
      dynamic postData = eventData['post'];
      if (postData is String) {
        postData = jsonDecode(postData) as Map<String, dynamic>;
      }
      if (postData == null || postData is! Map<String, dynamic>) {
        throw Exception('Post data is null or invalid in event');
      }

      final deletedPostUuid = postData['uuid'] as String?;
      if (deletedPostUuid == null) {
        throw Exception('Could not extract post UUID from deletion event');
      }

      // Remove post from the list
      final removedCount =
          _posts.where((post) => post.uuid == deletedPostUuid).length;
      _posts.removeWhere((post) => post.uuid == deletedPostUuid);

      // Clear selected post if it's the one being deleted
      if (_selectedPost?.uuid == deletedPostUuid) {
        _selectedPost = null;
        _logger.i(
          'BlogProvider: Selected post cleared (deleted: $deletedPostUuid)',
        );
      }

      _logger.i(
        'BlogProvider: Post deleted: $deletedPostUuid (removed $removedCount from list)',
      );
      notifyListeners();
    } catch (e) {
      _logger.e('BlogProvider: Error handling post.deleted event: $e');
      _errorMessage = 'Failed to process post deletion: $e';
      notifyListeners();
    }
  }

  /// Handle post liked event
  void _handlePostLiked(PusherEvent event) {
    try {
      _logger.i('BlogProvider: Received post.liked event: ${event.data}');

      final eventData = _parseEventData(event.data);
      dynamic postData = eventData['post'];
      if (postData is String) {
        postData = jsonDecode(postData) as Map<String, dynamic>;
      }
      if (postData == null || postData is! Map<String, dynamic>) {
        throw Exception('Post data is null or invalid in event');
      }

      final updatedPost = BlogPost.fromJson(postData);

      // Update post in the list
      final postIndex = _posts.indexWhere(
        (post) => post.uuid == updatedPost.uuid,
      );
      if (postIndex != -1) {
        _posts[postIndex] = updatedPost;
        _logger.i('BlogProvider: Post like updated: ${updatedPost.title}');
      }

      // Update selected post if it's the one being liked
      if (_selectedPost?.uuid == updatedPost.uuid) {
        _selectedPost = updatedPost;
        _logger.i(
          'BlogProvider: Selected post like updated: ${updatedPost.title}',
        );
      }

      notifyListeners();
    } catch (e) {
      _logger.e('BlogProvider: Error handling post.liked event: $e');
      _errorMessage = 'Failed to process post like: $e';
      notifyListeners();
    }
  }

  /// Handle post comment event
  void _handlePostComment(PusherEvent event) {
    try {
      _logger.i('BlogProvider: Received post.comment event: ${event.data}');

      final eventData = _parseEventData(event.data);
      dynamic postData = eventData['post'];
      if (postData is String) {
        postData = jsonDecode(postData) as Map<String, dynamic>;
      }
      if (postData == null || postData is! Map<String, dynamic>) {
        throw Exception('Post data is null or invalid in event');
      }

      final updatedPost = BlogPost.fromJson(postData);

      // Update post in the list
      final postIndex = _posts.indexWhere(
        (post) => post.uuid == updatedPost.uuid,
      );
      if (postIndex != -1) {
        _posts[postIndex] = updatedPost;
        _logger.i('BlogProvider: Post comment added: ${updatedPost.title}');
      }

      // Update selected post if it's the one receiving the comment
      if (_selectedPost?.uuid == updatedPost.uuid) {
        _selectedPost = updatedPost;
        _logger.i(
          'BlogProvider: Selected post comment updated: ${updatedPost.title}',
        );
      }

      notifyListeners();
    } catch (e) {
      _logger.e('BlogProvider: Error handling post.comment event: $e');
      _errorMessage = 'Failed to process post comment: $e';
      notifyListeners();
    }
  }

  /// Handle comment like event
  void _handleCommentLike(PusherEvent event) {
    try {
      _logger.i(
        'BlogProvider: Received post.comment.like event: ${event.data}',
      );

      final eventData = _parseEventData(event.data);
      dynamic postData = eventData['post'];
      if (postData is String) {
        postData = jsonDecode(postData) as Map<String, dynamic>;
      }
      if (postData == null || postData is! Map<String, dynamic>) {
        throw Exception('Post data is null or invalid in event');
      }

      final updatedPost = BlogPost.fromJson(postData);

      // Update post in the list
      final postIndex = _posts.indexWhere(
        (post) => post.uuid == updatedPost.uuid,
      );
      if (postIndex != -1) {
        _posts[postIndex] = updatedPost;
        _logger.i('BlogProvider: Comment like updated: ${updatedPost.title}');
      }

      // Update selected post if it's the one with the liked comment
      if (_selectedPost?.uuid == updatedPost.uuid) {
        _selectedPost = updatedPost;
        _logger.i(
          'BlogProvider: Selected post comment like updated: ${updatedPost.title}',
        );
      }

      notifyListeners();
    } catch (e) {
      _logger.e('BlogProvider: Error handling post.comment.like event: $e');
      _errorMessage = 'Failed to process comment like: $e';
      notifyListeners();
    }
  }

  /// Subscribe to post-specific events when viewing a specific post
  void subscribeToPostEvents(String postUuid) {
    if (!_pusherService.isInitialized) {
      _logger.w(
        'BlogProvider: PusherService not initialized, cannot subscribe to post events for $postUuid',
      );
      return;
    }

    _logger.i('BlogProvider: Subscribing to events for post: $postUuid');

    // Subscribe to post-specific channels
    _pusherService.subscribeToChannel('post.updated.$postUuid');
    _pusherService.subscribeToChannel('post.liked.$postUuid');
    _pusherService.subscribeToChannel('post.comment.$postUuid');
    _pusherService.subscribeToChannel('post.comment.like.$postUuid');

    // Bind to post-specific events with a small delay to ensure subscription
    Timer(const Duration(milliseconds: 100), () {
      _bindPostSpecificHandlers(postUuid);
    });
  }

  /// Unsubscribe from post-specific events
  void unsubscribeFromPostEvents(String postUuid) {
    if (!_pusherService.isInitialized) {
      _logger.w(
        'BlogProvider: PusherService not initialized, cannot unsubscribe from $postUuid',
      );
      return;
    }

    _logger.i('BlogProvider: Unsubscribing from events for post: $postUuid');

    _pusherService.unsubscribeFromChannel('post.updated.$postUuid');
    _pusherService.unsubscribeFromChannel('post.liked.$postUuid');
    _pusherService.unsubscribeFromChannel('post.comment.$postUuid');
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
      _logger.i('BlogProvider: Fetch posts response: ${response['data']}');

      if (response['statusCode'] == 200) {
        final List<dynamic> postsData = response['data'] ?? [];
        final newPosts =
            postsData.map((postJson) => BlogPost.fromJson(postJson)).toList();

        _hasMore = newPosts.isNotEmpty;
        _currentPage++;
        _posts = refresh ? newPosts : [..._posts, ...newPosts];
        _logger.i(
          'BlogProvider: Fetched ${newPosts.length} posts, total: ${_posts.length}',
        );

        // Initialize Pusher events if not already done
        if (!_pusherEventsInitialized && _pusherService.isInitialized) {
          _initializePusherEvents();
        }

        // Ensure event handlers are bound (especially after network issues)
        _ensureEventHandlers();
      } else {
        _errorMessage = response['message'] ?? 'Failed to load posts';
        _logger.e('BlogProvider: Failed to fetch posts: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch posts: $e';
      _logger.e('BlogProvider: Error fetching posts: $e');
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
        _logger.i('BlogProvider: Fetched post: ${_selectedPost!.title}');

        // Subscribe to real-time events for this specific post
        subscribeToPostEvents(postId);

        return _selectedPost;
      } else {
        _errorMessage = response['message'] ?? 'Failed to load post';
        _logger.e('BlogProvider: Failed to fetch post: $_errorMessage');
        return null;
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch post: $e';
      _logger.e('BlogProvider: Error fetching post: $e');
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

      _logger.i('BlogProvider: Post like response: ${response['data']}');
      if (response['statusCode'] == 200) {
        final updatedPost = BlogPost.fromJson(response['data']);

        // Update the post in the list if it exists
        final postIndex = _posts.indexWhere((post) => post.uuid == postId);
        if (postIndex != -1) {
          _posts[postIndex] = updatedPost;
          _logger.i('BlogProvider: Post like updated: ${updatedPost.title}');
        }

        // Update selected post if it's the one being liked
        if (_selectedPost?.uuid == postId) {
          _selectedPost = updatedPost;
          _logger.i(
            'BlogProvider: Selected post like updated: ${updatedPost.title}',
          );
        }

        notifyListeners();
        return true;
      }
      _logger.w('BlogProvider: Failed to like post: ${response['message']}');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to like post: $e';
      _logger.e('BlogProvider: Error liking post: $e');
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
          _logger.i(
            'BlogProvider: Selected post comment updated: ${updatedPost.title}',
          );
        }

        // Update the post in the list if it exists
        final postIndex = _posts.indexWhere((post) => post.uuid == postId);
        if (postIndex != -1) {
          _posts[postIndex] = updatedPost;
          _logger.i('BlogProvider: Post comment updated: ${updatedPost.title}');
        }

        // Find the new comment
        final newComment = updatedPost.comments.lastWhere(
          (c) =>
              !_selectedPost!.comments.any((existing) => existing.id == c.id),
          orElse: () => updatedPost.comments.last,
        );

        _logger.i(
          'BlogProvider: New comment added to post: ${updatedPost.title}',
        );
        notifyListeners();
        return newComment;
      }
      _logger.w('BlogProvider: Failed to add comment: ${response['message']}');
      return null;
    } catch (e) {
      _errorMessage = 'Failed to add comment: $e';
      _logger.e('BlogProvider: Error adding comment: $e');
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
          _logger.i(
            'BlogProvider: Selected post reply updated: ${updatedPost.title}',
          );
        }

        // Update the post in the list if it exists
        final postIndex = _posts.indexWhere((post) => post.uuid == postId);
        if (postIndex != -1) {
          _posts[postIndex] = updatedPost;
          _logger.i('BlogProvider: Post reply updated: ${updatedPost.title}');
        }

        // Find the new reply
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

          _logger.i('BlogProvider: New reply added to comment $commentId');
          notifyListeners();
          return newReply;
        }
      }
      _logger.w('BlogProvider: Failed to add reply: ${response['message']}');
      return null;
    } catch (e) {
      _errorMessage = 'Failed to add reply: $e';
      _logger.e('BlogProvider: Error adding reply: $e');
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
          _logger.i(
            'BlogProvider: Selected post comment like updated: ${updatedPost.title}',
          );
        }

        // Update the post in the list if it exists
        final postIndex = _posts.indexWhere((post) => post.uuid == postId);
        if (postIndex != -1) {
          _posts[postIndex] = updatedPost;
          _logger.i(
            'BlogProvider: Post comment like updated: ${updatedPost.title}',
          );
        }

        notifyListeners();
        return true;
      }
      _logger.w('BlogProvider: Failed to like comment: ${response['message']}');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to like comment: $e';
      _logger.e('BlogProvider: Error liking comment: $e');
      notifyListeners();
      return false;
    }
  }

  /// Public method to ensure event handlers are bound (can be called after network recovery)
  void ensureEventHandlers() {
    _ensureEventHandlers();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Select a post and subscribe to its events
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

  /// Refresh the provider state
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

    // Cancel pusher initialization subscription
    _pusherInitSubscription?.cancel();

    super.dispose();
  }
}
