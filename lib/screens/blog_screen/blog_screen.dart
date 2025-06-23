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

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch posts when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BlogProvider>().fetchPosts(refresh: true);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              CustomIntroText(text: 'Latest Today'),
              SizedBox(height: 10),
              Consumer<AdProvider>(
                builder: (context, adProvider, child) {
                  if (adProvider.isLoading) {
                    return Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: wawuColors.borderPrimary.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (adProvider.errorMessage != null) {
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
                          Text(
                            'Error loading ads',
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: () {
                              adProvider.fetchAds(); // Retry fetching ads
                            },
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (adProvider.ads.isEmpty) {
                    return Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: wawuColors.borderPrimary.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text('No Ads available')),
                    );
                  }

                  final List<Widget> carouselItems =
                      adProvider.ads.map((ad) {
                        return GestureDetector(
                          onTap: () async {
                            final url = ad.link;
                            if (url.isNotEmpty) {
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(
                                  Uri.parse(url),
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not open the ad link'),
                                  ),
                                );
                              }
                            }
                          },
                          child: Image.network(
                            ad.media.link,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: wawuColors.borderPrimary.withAlpha(50),
                                child: Center(
                                  child: Text('Failed to load image'),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList();
                  return FadingCarousel(height: 220, children: carouselItems);
                },
              ),
              SizedBox(height: 20),
              Consumer<BlogProvider>(
                builder: (context, blogProvider, child) {
                  if (blogProvider.isLoading && blogProvider.posts.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: wawuColors.primary,
                      ),
                    );
                  }

                  if (blogProvider.errorMessage != null &&
                      blogProvider.posts.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          Text(
                            'Error: ${blogProvider.errorMessage}',
                            style: TextStyle(color: Colors.red),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              blogProvider.fetchPosts(refresh: true);
                            },
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

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
                              'coverImage': post.coverImage.link,
                              'authorName': post.authorName,
                              'authorAvatar': post.authorAvatar ?? '',
                              'createdAt': post.formattedDate,
                            },
                          )
                          .toList();

                  // Get unique categories for filter
                  final categories = ['All'];
                  final uniqueCategories =
                      blogProvider.posts
                          .map((post) => post.category)
                          .toSet()
                          .toList();
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
                              builder: (context) => SingleBlogScreen(),
                            ),
                          );
                        },
                        onLike: () async {
                          final success = await blogProvider.toggleLikePost(
                            blogPost.uuid,
                          );
                          if (!success) {
                            _showSnackBar(
                              'Failed to like post. Please try again.',
                            );
                          }
                          return success;
                        },
                        onComment: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SingleBlogScreen(),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
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

    // Call the onLike callback and get the result
    await widget.onLike();

    // The parent widget will handle showing snackbar on failure
    // since it has access to the ScaffoldMessenger

    setState(() {
      _isLiking = false;
    });
  }

  String _formatCount(int count) {
    if (count >= 1000) {
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
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          spacing: 10.0,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.blogPost.coverImage.link,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(Icons.image_not_supported),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Column(
                spacing: 8.0,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.blogPost.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
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
                  Row(
                    spacing: 5.0,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 25,
                        padding: EdgeInsets.symmetric(horizontal: 8),
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
                            ),
                          ),
                        ),
                      ),
                      Row(
                        spacing: 5.0,
                        children: [
                          GestureDetector(
                            onTap: _handleLike,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              // width: 50,
                              height: 25,
                              decoration: BoxDecoration(
                                color:
                                    widget.blogPost.isLikedByCurrentUser
                                        ? wawuColors.primary.withAlpha(150)
                                        : wawuColors.primary.withAlpha(70),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
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
                                  Text(
                                    _formatCount(widget.blogPost.likes),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: wawuColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onComment,
                            child: Container(
                              // width: 30,
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              height: 25,
                              decoration: BoxDecoration(
                                color: wawuColors.primary.withAlpha(70),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.mode_comment_outlined,
                                    size: 10,
                                    color: wawuColors.primary,
                                  ),
                                  Text(
                                    _formatCount(
                                      widget.blogPost.comments.length,
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: wawuColors.primary,
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
