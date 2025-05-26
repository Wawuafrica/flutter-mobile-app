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
/// - Real-time blog updates via Pusher based on new event structure
class BlogProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;

  List<BlogPost> _posts = [];
  List<BlogPost> _featuredPosts = [];
  BlogPost? _selectedPost;
  bool _hasMorePosts = true;
  int _currentPage = 1;
  bool _isGeneralChannelSubscribed = false;
  String? _currentPostChannel;

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

    try {
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
        print('Failed to fetch blog posts: Invalid response');
        return [];
      }

      final List<dynamic> postsJson = response['posts'];
      final fetchedPosts = postsJson
          .map((json) => BlogPost.fromJson(json as Map<String, dynamic>))
          .toList();

      _hasMorePosts = response['has_more'] ?? false;
      _posts = refresh ? fetchedPosts : [..._posts, ...fetchedPosts];
      _currentPage++;

      if (!_isGeneralChannelSubscribed) {
        await _subscribeToGeneralBlogChannel();
      }

      notifyListeners();
      return _posts;
    } catch (e) {
      print('Failed to fetch blog posts: $e');
      return [];
    }
  }

  /// Fetches featured blog posts
  Future<List<BlogPost>> fetchFeaturedPosts() async {
    try {
      final response = await _apiService.get('/blog/featured');

      if (response['posts'] == null) {
        print('Failed to fetch featured posts: Invalid response');
        return [];
      }

      final List<dynamic> postsJson = response['posts'];
      _featuredPosts = postsJson
          .map((json) => BlogPost.fromJson(json as Map<String, dynamic>))
          .toList();

      notifyListeners();
      return _featuredPosts;
    } catch (e) {
      print('Failed to fetch featured posts: $e');
      return [];
    }
  }

  /// Fetches details of a specific blog post and subscribes to its channel
  Future<BlogPost?> fetchPostDetails(String postId) async {
    try {
      // Unsubscribe from previous post channel if any
      if (_currentPostChannel != null) {
        await _pusherService.unsubscribeFromChannel(_currentPostChannel!);
        _currentPostChannel = null;
      }

      final response = await _apiService.get('/blog/posts/$postId');

      if (response.isEmpty) {
        print('Failed to fetch post details: Empty response');
        return null;
      }

      final post = BlogPost.fromJson(response);
      _updatePostInLists(postId, post);
      _selectedPost = post;

      // Subscribe to the specific post channel
      await _subscribeToPostChannel(postId);

      notifyListeners();
      return post;
    } catch (e) {
      print('Failed to fetch post details: $e');
      return null;
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
        print('Failed to create blog post: Empty response');
        return null;
      }

      final post = BlogPost.fromJson(response);
      // The general channel will handle adding the new post via real-time update

      return post;
    } catch (e) {
      print('Failed to create blog post: $e');
      return null;
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
        print('Failed to update blog post: Empty response');
        return null;
      }

      final updatedPost = BlogPost.fromJson(response);
      // The specific post channel will handle updating the post via real-time update

      return updatedPost;
    } catch (e) {
      print('Failed to update blog post: $e');
      return null;
    }
  }

  /// Updates a post in posts and featuredPosts lists
  void _updatePostInLists(String postId, BlogPost updatedPost) {
    bool foundInPosts = false;
    for (int i = 0; i < _posts.length; i++) {
      if (_posts[i].id == postId) {
        if (updatedPost.isPublished()) {
          _posts[i] = updatedPost;
        } else {
          _posts.removeAt(i);
        }
        foundInPosts = true;
        break;
      }
    }

    if (!foundInPosts && updatedPost.isPublished()) {
      _posts.insert(0, updatedPost);
    }

    bool foundInFeatured = false;
    for (int i = 0; i < _featuredPosts.length; i++) {
      if (_featuredPosts[i].id == postId) {
        if (updatedPost.isFeatured) {
          _featuredPosts[i] = updatedPost;
        } else {
          _featuredPosts.removeAt(i);
        }
        foundInFeatured = true;
        break;
      }
    }

    if (!foundInFeatured && updatedPost.isFeatured) {
      _featuredPosts.insert(0, updatedPost);
    }

    // Sort lists after update/addition
    _posts.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    _featuredPosts.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    notifyListeners();
  }

  /// Removes a post from lists
  void _removePostFromLists(String postId) {
    _posts.removeWhere((post) => post.id == postId);
    _featuredPosts.removeWhere((post) => post.id == postId);
    if (_selectedPost?.id == postId) {
      _selectedPost = null;
    }
    notifyListeners();
  }

  /// Sets the selected blog post
  void selectPost(String postId) {
     try {
      // Unsubscribe from previous post channel if any
      if (_currentPostChannel != null) {
        _pusherService.unsubscribeFromChannel(_currentPostChannel!);
        _currentPostChannel = null;
      }

      _selectedPost = _posts.firstWhere(
        (post) => post.id == postId,
        orElse: () => _featuredPosts.firstWhere(
          (post) => post.id == postId,
          orElse: () => throw Exception('Blog post not found: $postId'),
        ),
      );

      // Subscribe to the specific post channel
      _subscribeToPostChannel(postId);

      notifyListeners();
    } catch (e) {
      print('Failed to select post: $e');
    }
  }

  /// Clears the selected blog post and unsubscribes from its channel
  void clearSelectedPost() {
    if (_currentPostChannel != null) {
      _pusherService.unsubscribeFromChannel(_currentPostChannel!);
      _currentPostChannel = null;
    }
    _selectedPost = null;
    notifyListeners();
  }

  /// Subscribes to the general blog channel for creates/deletes
  Future<void> _subscribeToGeneralBlogChannel() async {
    const channelName = 'posts';
    try {
      final channel = await _pusherService.subscribeToChannel(channelName);
      if (channel == null) {
        print('Failed to subscribe to general blog channel');
        return;
      }

      _isGeneralChannelSubscribed = true;

      // Bind to post created event
      _pusherService.bindToEvent(channelName, 'post.created', (data) {
        try {
          if (data is! String) {
            print('Invalid post.created event data');
            return;
          }
          final postData = jsonDecode(data) as Map<String, dynamic>;
          final post = BlogPost.fromJson(postData);

          if (post.isPublished()) {
            _posts.insert(0, post);
            if (post.isFeatured) {
              _featuredPosts.insert(0, post);
            }
            // No need to sort here, assuming new posts come in order or will be sorted on fetch
            notifyListeners();
          }
        } catch (e) {
          print('Failed to handle post.created event: $e');
        }
      });

       // Bind to post deleted event
      _pusherService.bindToEvent(channelName, 'post.deleted', (data) {
        try {
          if (data is! String) {
             print('Invalid post.deleted event data');
             return;
          }
          final deletedPostData = jsonDecode(data) as Map<String, dynamic>;
          final String? deletedPostId = deletedPostData['post_uuid'];

          if (deletedPostId != null) {
            _removePostFromLists(deletedPostId);
          } else {
             print('post.deleted event data missing post_uuid');
          }
        } catch (e) {
          print('Failed to handle post.deleted event: $e');
        }
      });

    } catch (e) {
      print('Failed to subscribe to general blog channel: $e');
    }
  }

  /// Subscribes to a specific post channel for updates, comments, and likes
  Future<void> _subscribeToPostChannel(String postId) async {
    final channelName = 'post.updated.\$postId'; // Using post.updated channel for general post events
     final commentChannelName = 'post.comment.\$postId';
     final likeChannelName = 'post.liked.\$postId';

    try {
       // Subscribe to updated channel
      final updatedChannel = await _pusherService.subscribeToChannel(channelName);
       if (updatedChannel != null) {
          _currentPostChannel = channelName; // Store only the main post channel

           _pusherService.bindToEvent(channelName, 'post.updated', (data) {
              try {
                if (data is! String) {
                  print('Invalid post.updated event data');
                  return;
                }
                final postData = jsonDecode(data) as Map<String, dynamic>;
                final updatedPost = BlogPost.fromJson(postData);
                 _updatePostInLists(updatedPost.id, updatedPost);
                if (_selectedPost?.id == updatedPost.id) {
                   _selectedPost = updatedPost;
                   notifyListeners();
                 }
              } catch (e) {
                 print('Failed to handle post.updated event: $e');
              }
           });
       }

       // Subscribe to comment channel
       final commentChannel = await _pusherService.subscribeToChannel(commentChannelName);
       if (commentChannel != null) {
          _pusherService.bindToEvent(commentChannelName, 'post.comment', (data) {
            try {
              if (data is! String) {
                print('Invalid post.comment event data');
                return;
              }
              final commentData = jsonDecode(data) as Map<String, dynamic>;
              // Assuming comment data structure allows adding to _selectedPost.comments
              // This requires BlogPost model to handle comments
              // If _selectedPost is the post this comment belongs to, add the comment.
               if (_selectedPost != null && _selectedPost!.id == postId) {
                 // Assuming commentData can be converted to a Comment object
                 // This requires a Comment model and a way to add it to BlogPost
                 // Example: _selectedPost!.comments.add(Comment.fromJson(commentData));
                 notifyListeners();
               }
            } catch (e) {
              print('Failed to handle post.comment event: $e');
            }
          });
       }

       // Subscribe to like channel
        final likeChannel = await _pusherService.subscribeToChannel(likeChannelName);
        if (likeChannel != null) {
           _pusherService.bindToEvent(likeChannelName, 'post.liked', (data) {
             try {
               if (data is! String) {
                 print('Invalid post.liked event data');
                 return;
               }
               final likeData = jsonDecode(data) as Map<String, dynamic>;
               // Assuming like data structure allows updating like count or user list
               // If _selectedPost is the post this like belongs to, update like status/count.
               if (_selectedPost != null && _selectedPost!.id == postId) {
                  // Example: _selectedPost!.likesCount = likeData['likes_count'];
                  notifyListeners();
               }
             } catch (e) {
               print('Failed to handle post.liked event: $e');
             }
           });
        }

        // Note: post.comment.like.{post_uuid} is not implemented here as it requires more specific Comment ID handling

    } catch (e) {
      print('Failed to subscribe to post channel \$postId: \$e');
       _currentPostChannel = null; // Clear channel on failure
    }
  }

  /// Clears all blog data
  void clearAll() {
    _posts = [];
    _featuredPosts = [];
    _selectedPost = null;
    _hasMorePosts = true;
    _currentPage = 1;
    _isGeneralChannelSubscribed = false;
    if (_currentPostChannel != null) {
      _pusherService.unsubscribeFromChannel(_currentPostChannel!);
      _currentPostChannel = null;
    }
    resetState();
  }

  @override
  void dispose() {
    if (_isGeneralChannelSubscribed) {
      _pusherService.unsubscribeFromChannel('posts');
    }
     if (_currentPostChannel != null) {
       _pusherService.unsubscribeFromChannel(_currentPostChannel!);
     }
    super.dispose();
  }
}
