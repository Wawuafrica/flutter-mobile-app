import '../models/blog_post.dart';
import '../services/api_service.dart';
import 'base_provider.dart';

/// BlogProvider manages the state of blog posts.
///
/// This provider handles:
/// - Fetching blog posts with pagination
/// - Fetching single post details
/// - Liking/unliking posts
/// - Adding comments and sub-comments
/// - Liking comments
class BlogProvider extends BaseProvider {
  final ApiService _apiService;
  List<BlogPost> _posts = [];
  BlogPost? _selectedPost;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;

  // Getters
  List<BlogPost> get posts => _posts;
  BlogPost? get selectedPost => _selectedPost;
  @override
  bool get isLoading => _isLoading;
  @override
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  BlogProvider({required ApiService apiService}) : _apiService = apiService;

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

      if (response['statusCode'] == 200) {
        final updatedPost = BlogPost.fromJson(response['data']);

        // Update the post in the list if it exists
        final postIndex = _posts.indexWhere((post) => post.uuid == postId);
        if (postIndex != -1) {
          _posts[postIndex] = updatedPost;
        }

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
    _selectedPost = post;
    setSuccess();
  }

  // Refresh the provider state
  void refresh() {
    _posts = [];
    _selectedPost = null;
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();
  }
}
