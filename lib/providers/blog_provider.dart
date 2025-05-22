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
    try {
      if (refresh) {
        _currentPage = 1;
        _hasMorePosts = true;
      }

      if (!_hasMorePosts && !refresh) {
        return _posts;
      }

      final response = await _apiService.get(
        '/blog/posts',
        queryParameters: {
          'page': _currentPage.toString(),
          'limit': '10',
          'status': 'published',
          if (categories != null && categories.isNotEmpty)
            'categories': categories.join(','),
          if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
          if (authorId != null) 'author_id': authorId,
        },
      );

      if (response['posts'] == null) {
        throw Exception('Failed to fetch blog posts: Invalid response');
      }

      final List<dynamic> postsJson = response['posts'];
      final fetchedPosts = postsJson
          .map((json) => BlogPost.fromJson(json as Map<String, dynamic>))
          .toList();

      _hasMorePosts = response['has_more'] ?? false;
      _posts = refresh ? fetchedPosts : [..._posts, ...fetchedPosts];
      _currentPage++;

      if (!_isSubscribed) {
        await _subscribeToBlogChannel();
      }

      notifyListeners();
      return _posts;
    } catch (e) {
      throw Exception('Failed to fetch blog posts: $e');
    }
  }

  /// Fetches featured blog posts
  Future<List<BlogPost>> fetchFeaturedPosts() async {
    try {
      final response = await _apiService.get('/blog/featured');

      if (response['posts'] == null) {
        throw Exception('Failed to fetch featured posts: Invalid response');
      }

      final List<dynamic> postsJson = response['posts'];
      _featuredPosts = postsJson
          .map((json) => BlogPost.fromJson(json as Map<String, dynamic>))
          .toList();

      notifyListeners();
      return _featuredPosts;
    } catch (e) {
      throw Exception('Failed to fetch featured posts: $e');
    }
  }

  /// Fetches details of a specific blog post
  Future<BlogPost?> fetchPostDetails(String postId) async {
    try {
      final response = await _apiService.get('/blog/posts/$postId');

      if (response.isEmpty) {
        throw Exception('Failed to fetch post details: Empty response');
      }

      final post = BlogPost.fromJson(response);
      _updatePostInLists(postId, post);
      _selectedPost = post;

      notifyListeners();
      return post;
    } catch (e) {
      throw Exception('Failed to fetch post details: $e');
    }
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
    try {
      final response = await _apiService.post(
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

      if (response.isEmpty) {
        throw Exception('Failed to create blog post: Empty response');
      }

      final post = BlogPost.fromJson(response);
      if (post.isPublished()) {
        _posts.insert(0, post);
        if (post.isFeatured) {
          _featuredPosts.insert(0, post);
        }
      }

      notifyListeners();
      return post;
    } catch (e) {
      throw Exception('Failed to create blog post: $e');
    }
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
    try {
      final response = await _apiService.put(
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

      if (response.isEmpty) {
        throw Exception('Failed to update blog post: Empty response');
      }

      final updatedPost = BlogPost.fromJson(response);
      _updatePostInLists(postId, updatedPost);
      if (_selectedPost?.id == postId) {
        _selectedPost = updatedPost;
      }

      notifyListeners();
      return updatedPost;
    } catch (e) {
      throw Exception('Failed to update blog post: $e');
    }
  }

  /// Updates a post in posts and featuredPosts lists
  void _updatePostInLists(String postId, BlogPost updatedPost) {
    _posts = _posts.map((post) {
      return post.id == postId && updatedPost.isPublished() ? updatedPost : post;
    }).where((post) => post.isPublished()).toList();

    if (updatedPost.isPublished() && !_posts.any((post) => post.id == postId)) {
      _posts.insert(0, updatedPost);
    }

    _featuredPosts = _featuredPosts.map((post) {
      return post.id == postId && updatedPost.isFeatured ? updatedPost : post;
    }).where((post) => post.isFeatured).toList();

    if (updatedPost.isFeatured && !_featuredPosts.any((post) => post.id == postId)) {
      _featuredPosts.insert(0, updatedPost);
    }
  }

  /// Sets the selected blog post
  void selectPost(String postId) {
    try {
      _selectedPost = _posts.firstWhere(
        (post) => post.id == postId,
        orElse: () => _featuredPosts.firstWhere(
          (post) => post.id == postId,
          orElse: () => throw Exception('Blog post not found: $postId'),
        ),
      );
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to select post: $e');
    }
  }

  /// Clears the selected blog post
  void clearSelectedPost() {
    _selectedPost = null;
    notifyListeners();
  }

  /// Subscribes to blog channel for real-time updates
  Future<void> _subscribeToBlogChannel() async {
    const channelName = 'blog';
    try {
      final channel = await _pusherService.subscribeToChannel(channelName);
      if (channel == null) {
        throw Exception('Failed to subscribe to blog channel');
      }

      _isSubscribed = true;

      _pusherService.bindToEvent(channelName, 'post-created', (data) {
        try {
          if (data is! String) {
            throw Exception('Invalid post-created event data');
          }
          final postData = jsonDecode(data) as Map<String, dynamic>;
          final post = BlogPost.fromJson(postData);

          if (post.isPublished()) {
            _posts.insert(0, post);
            if (post.isFeatured) {
              _featuredPosts.insert(0, post);
            }
            notifyListeners();
          }
        } catch (e) {
          throw Exception('Failed to handle post-created event: $e');
        }
      });

      _pusherService.bindToEvent(channelName, 'post-updated', (data) {
        try {
          if (data is! String) {
            throw Exception('Invalid post-updated event data');
          }
          final postData = jsonDecode(data) as Map<String, dynamic>;
          final updatedPost = BlogPost.fromJson(postData);
          _updatePostInLists(updatedPost.id, updatedPost);
          if (_selectedPost?.id == updatedPost.id) {
            _selectedPost = updatedPost;
          }
          notifyListeners();
        } catch (e) {
          throw Exception('Failed to handle post-updated event: $e');
        }
      });
    } catch (e) {
      throw Exception('Failed to subscribe to blog channel: $e');
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