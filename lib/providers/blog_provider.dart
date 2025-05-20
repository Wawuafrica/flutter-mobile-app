import 'dart:convert';
import '../models/blog_post.dart';
import '../providers/base_provider.dart';
import '../services/api_service.dart';
import '../services/pusher_service.dart';

/// BlogProvider manages the state of blog posts.
///
/// This provider handles:
/// - Fetching blog posts with filtering and pagination
/// - Fetching featured posts
/// - Fetching post details
/// - Creating and updating posts (for authorized users)
/// - Real-time blog updates via Pusher
class BlogProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;

  List<BlogPost> _posts = [];
  List<BlogPost> _featuredPosts = [];
  BlogPost? _selectedPost;
  bool _hasMorePosts = true;
  int _currentPage = 1;
  bool _isSubscribed = false;

  // Getters
  List<BlogPost> get posts => _posts;
  List<BlogPost> get featuredPosts => _featuredPosts;
  BlogPost? get selectedPost => _selectedPost;
  bool get hasMorePosts => _hasMorePosts;
  int get currentPage => _currentPage;

  BlogProvider({ApiService? apiService, PusherService? pusherService})
    : _apiService = apiService ?? ApiService(),
      _pusherService = pusherService ?? PusherService();

  /// Fetches blog posts with optional filtering and pagination
  Future<List<BlogPost>> fetchPosts({
    List<String>? categories,
    List<String>? tags,
    String? authorId,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMorePosts = true;
    }

    if (!_hasMorePosts && !refresh) {
      return _posts;
    }

    final result = await handleAsync(() async {
      // TODO: Replace with actual endpoint
      final response = await _apiService.get<Map<String, dynamic>>(
        '/blog/posts',
        queryParameters: {
          'page': _currentPage.toString(),
          'limit': '10', // Fixed page size of 10 posts
          'status': 'published',
          if (categories != null && categories.isNotEmpty)
            'categories': categories.join(','),
          if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
          if (authorId != null) 'author_id': authorId,
        },
      );

      final List<dynamic> postsJson = response['posts'] as List<dynamic>;
      final List<BlogPost> fetchedPosts =
          postsJson
              .map((json) => BlogPost.fromJson(json as Map<String, dynamic>))
              .toList();

      final bool hasMorePages = response['has_more'] as bool? ?? false;

      if (refresh) {
        _posts = fetchedPosts;
      } else {
        _posts.addAll(fetchedPosts);
      }

      _hasMorePosts = hasMorePages;
      _currentPage++;

      // Subscribe to blog channel if not already subscribed
      if (!_isSubscribed) {
        await _subscribeToBlogChannel();
      }

      return _posts;
    }, errorMessage: 'Failed to fetch blog posts');

    return result ?? [];
  }

  /// Fetches featured blog posts
  Future<List<BlogPost>> fetchFeaturedPosts() async {
    final result = await handleAsync(() async {
      // TODO: Replace with actual endpoint
      final response = await _apiService.get<Map<String, dynamic>>(
        '/blog/featured',
      );

      final List<dynamic> postsJson = response['posts'] as List<dynamic>;
      final List<BlogPost> featured =
          postsJson
              .map((json) => BlogPost.fromJson(json as Map<String, dynamic>))
              .toList();

      _featuredPosts = featured;

      return featured;
    }, errorMessage: 'Failed to fetch featured posts');

    return result ?? [];
  }

  /// Fetches details of a specific blog post
  Future<BlogPost?> fetchPostDetails(String postId) async {
    return await handleAsync(() async {
      // TODO: Replace with actual endpoint
      final response = await _apiService.get<Map<String, dynamic>>(
        '/blog/posts/$postId',
      );

      final post = BlogPost.fromJson(response);

      // Update in posts list if already loaded
      for (int i = 0; i < _posts.length; i++) {
        if (_posts[i].id == postId) {
          _posts[i] = post;
          break;
        }
      }

      // Update in featured posts if present
      for (int i = 0; i < _featuredPosts.length; i++) {
        if (_featuredPosts[i].id == postId) {
          _featuredPosts[i] = post;
          break;
        }
      }

      _selectedPost = post;

      return post;
    }, errorMessage: 'Failed to fetch post details');
  }

  /// Creates a new blog post (for authorized users)
  Future<BlogPost?> createPost({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    required List<String> categories,
    required List<String> tags,
    String? featuredImageUrl,
    bool isFeatured = false,
    String status = 'draft',
  }) async {
    return await handleAsync(() async {
      // TODO: Replace with actual endpoint
      final response = await _apiService.post<Map<String, dynamic>>(
        '/blog/posts',
        data: {
          'title': title,
          'content': content,
          'author_id': authorId,
          'author_name': authorName,
          'author_avatar_url': authorAvatarUrl,
          'categories': categories,
          'tags': tags,
          'featured_image_url': featuredImageUrl,
          'is_featured': isFeatured,
          'status': status,
        },
      );

      final post = BlogPost.fromJson(response);

      // Add to posts list if it's published
      if (post.isPublished()) {
        _posts.insert(0, post);

        // Add to featured posts if it's featured
        if (post.isFeatured) {
          _featuredPosts.insert(0, post);
        }
      }

      return post;
    }, errorMessage: 'Failed to create blog post');
  }

  /// Updates an existing blog post (for authorized users)
  Future<BlogPost?> updatePost({
    required String postId,
    String? title,
    String? content,
    List<String>? categories,
    List<String>? tags,
    String? featuredImageUrl,
    bool? isFeatured,
    String? status,
  }) async {
    return await handleAsync(() async {
      // TODO: Replace with actual endpoint
      final response = await _apiService.put<Map<String, dynamic>>(
        '/blog/posts/$postId',
        data: {
          if (title != null) 'title': title,
          if (content != null) 'content': content,
          if (categories != null) 'categories': categories,
          if (tags != null) 'tags': tags,
          if (featuredImageUrl != null) 'featured_image_url': featuredImageUrl,
          if (isFeatured != null) 'is_featured': isFeatured,
          if (status != null) 'status': status,
        },
      );

      final updatedPost = BlogPost.fromJson(response);

      // Update in posts list if present
      for (int i = 0; i < _posts.length; i++) {
        if (_posts[i].id == postId) {
          // Remove if it's no longer published
          if (!updatedPost.isPublished()) {
            _posts.removeAt(i);
          } else {
            _posts[i] = updatedPost;
          }
          break;
        }
      }

      // Update in featured posts if present or add if now featured
      bool foundInFeatured = false;
      for (int i = 0; i < _featuredPosts.length; i++) {
        if (_featuredPosts[i].id == postId) {
          foundInFeatured = true;
          // Remove if no longer featured
          if (!updatedPost.isFeatured) {
            _featuredPosts.removeAt(i);
          } else {
            _featuredPosts[i] = updatedPost;
          }
          break;
        }
      }

      // Add to featured if it's now featured but wasn't before
      if (!foundInFeatured && updatedPost.isFeatured) {
        _featuredPosts.add(updatedPost);
      }

      // Update selected post if it's the one being edited
      if (_selectedPost != null && _selectedPost!.id == postId) {
        _selectedPost = updatedPost;
      }

      return updatedPost;
    }, errorMessage: 'Failed to update blog post');
  }

  /// Sets the selected blog post
  void selectPost(String postId) {
    _selectedPost = _posts.firstWhere(
      (post) => post.id == postId,
      orElse:
          () => _featuredPosts.firstWhere(
            (post) => post.id == postId,
            orElse: () => throw Exception('Blog post not found: $postId'),
          ),
    );

    notifyListeners();
  }

  /// Clears the selected blog post
  void clearSelectedPost() {
    _selectedPost = null;
    notifyListeners();
  }

  /// Subscribes to blog channel for real-time updates
  Future<void> _subscribeToBlogChannel() async {
    // Channel name: 'blog'
    const channelName = 'blog';

    final channel = await _pusherService.subscribeToChannel(channelName);
    if (channel != null) {
      _isSubscribed = true;

      // Bind to post created event
      _pusherService.bindToEvent(channelName, 'post-created', (data) async {
        if (data is String) {
          final postData = jsonDecode(data) as Map<String, dynamic>;
          final post = BlogPost.fromJson(postData);

          // Add to posts list if it's published
          if (post.isPublished()) {
            _posts.insert(0, post);

            // Add to featured posts if it's featured
            if (post.isFeatured) {
              _featuredPosts.insert(0, post);
            }

            notifyListeners();
          }
        }
      });

      // Bind to post updated event
      _pusherService.bindToEvent(channelName, 'post-updated', (data) async {
        if (data is String) {
          final postData = jsonDecode(data) as Map<String, dynamic>;
          final updatedPost = BlogPost.fromJson(postData);

          // Update in posts list
          bool updatedInPosts = false;
          for (int i = 0; i < _posts.length; i++) {
            if (_posts[i].id == updatedPost.id) {
              updatedInPosts = true;
              // Remove if it's no longer published
              if (!updatedPost.isPublished()) {
                _posts.removeAt(i);
              } else {
                _posts[i] = updatedPost;
              }
              break;
            }
          }

          // Add to posts if it's now published but wasn't before
          if (!updatedInPosts && updatedPost.isPublished()) {
            _posts.insert(0, updatedPost);
          }

          // Update in featured posts
          bool foundInFeatured = false;
          for (int i = 0; i < _featuredPosts.length; i++) {
            if (_featuredPosts[i].id == updatedPost.id) {
              foundInFeatured = true;
              // Remove if no longer featured
              if (!updatedPost.isFeatured) {
                _featuredPosts.removeAt(i);
              } else {
                _featuredPosts[i] = updatedPost;
              }
              break;
            }
          }

          // Add to featured if it's now featured but wasn't before
          if (!foundInFeatured && updatedPost.isFeatured) {
            _featuredPosts.add(updatedPost);
          }

          // Update selected post if it's the one being updated
          if (_selectedPost != null && _selectedPost!.id == updatedPost.id) {
            _selectedPost = updatedPost;
          }

          notifyListeners();
        }
      });
    }
  }

  /// Clears all blog data
  void clearAll() {
    _posts = [];
    _featuredPosts = [];
    _selectedPost = null;
    _hasMorePosts = true;
    _currentPage = 1;
    _isSubscribed = false;
    resetState();
  }

  @override
  void dispose() {
    if (_isSubscribed) {
      _pusherService.unsubscribeFromChannel('blog');
    }
    super.dispose();
  }
}
