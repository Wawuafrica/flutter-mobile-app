import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/ad_provider.dart';
import 'package:wawu_mobile/providers/blog_provider.dart';
import 'package:wawu_mobile/models/blog_post.dart';
import 'package:wawu_mobile/screens/blog_screen/single_blog_screen/single_blog_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/fading_carousel/fading_carousel.dart';
import 'package:wawu_mobile/widgets/filterable_widget/filterable_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import the package
import 'package:wawu_mobile/widgets/custom_snackbar.dart'; // Import CustomSnackBar
import 'package:wawu_mobile/widgets/full_ui_error_display.dart'; // Import FullErrorDisplay

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Flags to prevent showing multiple snackbars for the same error
  bool _hasShownAdError = false;
  bool _hasShownBlogError = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Initialize data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final blogProvider = context.read<BlogProvider>();
      final adProvider = context.read<AdProvider>();

      // Fetch blog posts
      blogProvider.fetchPosts(refresh: true);

      // Initialize ads (will fetch if not already loaded)
      adProvider.refresh();
    });
  }

  Future<void> _refreshData() async {
    try {
      final blogProvider = context.read<BlogProvider>();
      final adProvider = context.read<AdProvider>();

      // Create a list of futures to run in parallel
      final futures = <Future>[
        blogProvider.fetchPosts(refresh: true),
        adProvider.refresh(), // Use refresh instead of fetchAds
      ];

      // Wait for all futures to complete
      await Future.wait(futures);

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

  Future<void> _handleAdTap(String adLink) async {
    if (adLink.isEmpty) {
      CustomSnackBar.show(
        context,
        message: 'Ad link is not available',
        isError: false, // Informative, not an error
      );
      return;
    }

    try {
      final uri = Uri.parse(adLink);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        CustomSnackBar.show(
          context,
          message: 'Could not open the ad link',
          isError: true,
        );
      }
    } catch (e) {
      CustomSnackBar.show(
        context,
        message: 'Invalid ad link format',
        isError: true,
      );
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

  Widget _buildAdCarousel() {
    return Consumer<AdProvider>(
      builder: (context, adProvider, child) {
        // Listen for errors from AdProvider and display SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (adProvider.hasError &&
              adProvider.errorMessage != null &&
              !_hasShownAdError) {
            CustomSnackBar.show(
              context,
              message: adProvider.errorMessage!,
              isError: true,
              actionLabel: 'RETRY',
              onActionPressed: () {
                adProvider.fetchAds();
              },
            );
            _hasShownAdError = true;
            adProvider.clearError(); // Clear error state
          } else if (!adProvider.hasError && _hasShownAdError) {
            _hasShownAdError = false;
          }
        });

        // Loading state
        if (adProvider.isLoading && adProvider.ads.isEmpty) {
          return Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: wawuColors.borderPrimary.withAlpha(50),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text(
                    'Loading ads...',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        // Error state with FullErrorDisplay
        if (adProvider.hasError &&
            adProvider.ads.isEmpty &&
            !adProvider.isLoading) {
          return FullErrorDisplay(
            errorMessage:
                adProvider.errorMessage ??
                'Failed to load ads. Please try again.',
            onRetry: () {
              adProvider.fetchAds();
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
        if (adProvider.ads.isEmpty) {
          return Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: wawuColors.borderPrimary.withAlpha(50),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'No ads available',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check back later for promotions',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          );
        }

        // Success state with ads
        final List<Widget> carouselItems =
            adProvider.ads.map((ad) {
              return GestureDetector(
                onTap: () => _handleAdTap(ad.link),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: ad.media.link,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 220,
                    placeholder:
                        (context, url) => Container(
                          width: double.infinity,
                          height: 220,
                          decoration: BoxDecoration(
                            color: wawuColors.borderPrimary.withAlpha(50),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    wawuColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Loading ad...',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          width: double.infinity,
                          height: 220,
                          decoration: BoxDecoration(
                            color: wawuColors.borderPrimary.withAlpha(50),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load ad',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                ),
              );
            }).toList();

        return FadingCarousel(height: 220, children: carouselItems);
      },
    );
  }

  Widget _buildBlogContent() {
    return Consumer<BlogProvider>(
      builder: (context, blogProvider, child) {
        // Listen for errors from BlogProvider and display SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (blogProvider.hasError &&
              blogProvider.errorMessage != null &&
              !_hasShownBlogError) {
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

        // Error state with FullErrorDisplay
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
        final blogPostsAsMap =
            blogProvider.posts
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
    return Scaffold(
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshData,
        color: Theme.of(context).primaryColor,
        backgroundColor: Colors.white,
        displacement: 40.0,
        strokeWidth: 2.0,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  const CustomIntroText(text: 'Latest Today'),
                  const SizedBox(height: 10),
                  _buildAdCarousel(),
                  const SizedBox(height: 20),
                  _buildBlogContent(),
                  const SizedBox(height: 20), // Add bottom padding
                ]),
              ),
            ),
          ],
        ),
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
        width: double.infinity,
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        margin: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: widget.blogPost.coverImage?.link ?? '',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            wawuColors.primary,
                          ),
                        ),
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey[500],
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.blogPost.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            widget.blogPost.content.replaceAll(
                              RegExp(r'<[^>]*>'),
                              '',
                            ), // Remove HTML tags
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 25,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: wawuColors.primary.withAlpha(70),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Center(
                          child: Text(
                            widget.blogPost.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: wawuColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _handleLike,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              height: 25,
                              decoration: BoxDecoration(
                                color:
                                    widget.blogPost.isLikedByCurrentUser
                                        ? wawuColors.primary.withAlpha(150)
                                        : wawuColors.primary.withAlpha(70),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _isLiking
                                      ? SizedBox(
                                        width: 10,
                                        height: 10,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1,
                                          color: wawuColors.primary,
                                        ),
                                      )
                                      : Icon(
                                        widget.blogPost.isLikedByCurrentUser
                                            ? Icons.thumb_up_alt
                                            : Icons.thumb_up_alt_outlined,
                                        size: 10,
                                        color: wawuColors.primary,
                                      ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatCount(widget.blogPost.likes),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: wawuColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: widget.onComment,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              height: 25,
                              decoration: BoxDecoration(
                                color: wawuColors.primary.withAlpha(70),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.mode_comment_outlined,
                                    size: 10,
                                    color: wawuColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatCount(
                                      widget.blogPost.comments.length,
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: wawuColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
