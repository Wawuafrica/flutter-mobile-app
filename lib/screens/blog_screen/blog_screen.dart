import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/blog_provider.dart';
import 'package:wawu_mobile/models/blog_post.dart';
import 'package:wawu_mobile/screens/blog_screen/single_blog_screen/single_blog_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/filterable_widget/filterable_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart';
import 'package:wawu_mobile/widgets/full_ui_error_display.dart';

class BlogScreen extends StatefulWidget {
    final ValueChanged<double>? onScroll; // Changed to ValueChanged<double>

  const BlogScreen({super.key, this.onScroll});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

late ScrollController _internalScrollController; // Internal scroll controller
  // Flag to prevent showing multiple snackbars for the same error
  bool _hasShownBlogError = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
        _internalScrollController = ScrollController();
    _internalScrollController.addListener(_handleScroll);
  }

  
  @override
  void dispose() {
    _internalScrollController.removeListener(_handleScroll);
    _internalScrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (widget.onScroll != null) {
      widget.onScroll!(_internalScrollController.offset);
    }
  }


  void _initializeData() {
    // Initialize data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final blogProvider = context.read<BlogProvider>();

      // Fetch blog posts
      blogProvider.fetchPosts(refresh: true);
    });
  }

  Future<void> _refreshData() async {
    try {
      final blogProvider = context.read<BlogProvider>();

      // Fetch blog posts
      await blogProvider.fetchPosts(refresh: true);

      // Show success message
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Content refreshed successfully',
          isError: false,
        );
      }
    } catch (error) {
      // Show error message
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Failed to refresh data: $error',
          isError: true,
        );
      }
    }
  }

  // Function to show the support dialog (can be reused)
  void _showErrorSupportDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Contact Support',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: wawuColors.primary,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: wawuColors.buttonSecondary),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Check if any provider has a critical error (empty data + error + not loading)
  bool _hasCriticalError(
    BlogProvider blogProvider,
  ) {
    if (blogProvider.hasError &&
        blogProvider.posts.isEmpty &&
        !blogProvider.isLoading) {
      return true;
    }
    return false;
  }

  /// Get the primary error message and retry function
  Map<String, dynamic> _getPrimaryError(
    BlogProvider blogProvider,
  ) {
    if (blogProvider.hasError &&
        blogProvider.posts.isEmpty &&
        !blogProvider.isLoading) {
      return {
        'message': blogProvider.errorMessage ?? 'Failed to load blog posts',
        'retry': () => blogProvider.fetchPosts(refresh: true),
      };
    }
    return {
      'message': 'Something went wrong',
      'retry': () => _initializeData(),
    };
  }

  /// Check if any provider is loading (for overall loading state)
  bool _isAnyProviderLoading(
    BlogProvider blogProvider,
  ) {
    return (blogProvider.isLoading && blogProvider.posts.isEmpty);
  }

  Widget _buildBlogContent() {
    return Consumer<BlogProvider>(
      builder: (context, blogProvider, child) {
        // Only show snackbar errors when there's existing data and a transient error occurs
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (blogProvider.hasError &&
              blogProvider.errorMessage != null &&
              !_hasShownBlogError &&
              blogProvider.posts.isNotEmpty) {
            // Only show snackbar if there's existing data
            CustomSnackBar.show(
              context,
              message: blogProvider.errorMessage!,
              isError: true,
              actionLabel: 'RETRY',
              onActionPressed: () {
                blogProvider.fetchPosts(refresh: true);
              },
            );
            _hasShownBlogError = true;
            blogProvider.clearError(); // Clear error state
          } else if (!blogProvider.hasError && _hasShownBlogError) {
            _hasShownBlogError = false;
          }
        });

        // Loading state
        if (blogProvider.isLoading && blogProvider.posts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading blog posts...',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        // Error state with FullErrorDisplay - only when there's no data
        if (blogProvider.hasError &&
            blogProvider.posts.isEmpty &&
            !blogProvider.isLoading) {
          return FullErrorDisplay(
            errorMessage:
                blogProvider.errorMessage ??
                'Failed to load blog posts. Please try again.',
            onRetry: () {
              blogProvider.fetchPosts(refresh: true);
            },
            onContactSupport: () {
              _showErrorSupportDialog(
                context,
                'If this problem persists, please contact our support team. We are here to help!',
              );
            },
          );
        }

        // Empty state
        if (blogProvider.posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No blog posts available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for new content',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        }

        // Success state with posts
        // Convert BlogPost list to Map format for FilterableWidgetList
        final blogPostsAsMap = blogProvider.posts
            .map(
              (post) => {
                'uuid': post.uuid,
                'title': post.title,
                'content': post.content,
                'category': post.category,
                'likes': post.likes.toString(),
                'comments': post.comments.length.toString(),
                'coverImage': post.coverImage?.link ?? '',
                'authorName': post.authorName,
                'authorAvatar': post.authorAvatar ?? '',
                'createdAt': post.formattedDate,
              },
            )
            .toList();

        // Get unique categories for filter
        final categories = ['All'];
        final uniqueCategories =
            blogProvider.posts.map((post) => post.category).toSet().toList();
        categories.addAll(uniqueCategories);

        return FilterableWidgetList(
          widgets: blogPostsAsMap,
          filterOptions: categories,
          itemBuilder: (widgetData) {
            // Find the actual BlogPost object
            final blogPost = blogProvider.posts.firstWhere(
              (post) => post.uuid == widgetData['uuid'],
            );

            return BlogListItem(
              blogPost: blogPost,
              onTap: () {
                blogProvider.selectPost(blogPost);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SingleBlogScreen(),
                  ),
                );
              },
              onLike: () async {
                final success = await blogProvider.toggleLikePost(
                  blogPost.uuid,
                );
                if (!success) {
                  CustomSnackBar.show(
                    context,
                    message: 'Failed to like post. Please try again.',
                    isError: true,
                  );
                }
                return success;
              },
              onComment: () {
                blogProvider.selectPost(blogPost);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SingleBlogScreen(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _refreshData,
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      displacement: 40.0,
      strokeWidth: 2.0,
      child: CustomScrollView(
        controller: _internalScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0), // Added top padding to match Home Screen
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                Text(
                  'Exploring New Articles',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 15),
                _buildBlogContent(),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class BlogListItem extends StatefulWidget {
  final BlogPost blogPost;
  final VoidCallback onTap;
  final Future<bool> Function() onLike;
  final VoidCallback onComment;

  const BlogListItem({
    super.key,
    required this.blogPost,
    required this.onTap,
    required this.onLike,
    required this.onComment,
  });

  @override
  State<BlogListItem> createState() => _BlogListItemState();
}

class _BlogListItemState extends State<BlogListItem> {
  bool _isLiking = false;

  void _handleLike() async {
    if (_isLiking) return;

    setState(() {
      _isLiking = true;
    });

    try {
      await widget.onLike();
    } finally {
      if (mounted) {
        setState(() {
          _isLiking = false;
        });
      }
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: widget.blogPost.coverImage?.link ?? '',
                height: 180, // Reduced height
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(wawuColors.primary),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.grey[400],
                    size: 50,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.blogPost.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: wawuColors.primary.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      widget.blogPost.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _handleLike,
                            child: _isLiking
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: wawuColors.primary,
                                    ),
                                  )
                                : Icon(
                                    widget.blogPost.isLikedByCurrentUser
                                        ? Icons.thumb_up
                                        : Icons.thumb_up_alt_outlined,
                                    size: 18,
                                    color: wawuColors.primary,
                                  ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatCount(widget.blogPost.likes),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: widget.onComment,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              size: 18,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatCount(widget.blogPost.comments.length),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}