import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/blog_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/models/blog_post.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/fading_carousel/fading_carousel.dart';

class SingleBlogScreen extends StatefulWidget {
  const SingleBlogScreen({super.key});

  @override
  State<SingleBlogScreen> createState() => _SingleBlogScreenState();
}

class _SingleBlogScreenState extends State<SingleBlogScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  bool _isLikingPost = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    final blogProvider = context.read<BlogProvider>();
    final selectedPost = blogProvider.selectedPost;

    if (selectedPost == null) {
      _showSnackBar('No blog post selected');
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    final newComment = await blogProvider.addComment(
      selectedPost.uuid,
      comment,
    );

    setState(() {
      _isSubmittingComment = false;
    });

    if (newComment != null) {
      _commentController.clear();
      _showSnackBar('Comment added successfully!', isError: false);
    } else {
      _showSnackBar('Failed to add comment. Please try again.');
    }
  }

  Future<void> _handleLikePost(String postId) async {
    if (_isLikingPost) return;

    setState(() {
      _isLikingPost = true;
    });

    final blogProvider = context.read<BlogProvider>();
    final success = await blogProvider.toggleLikePost(postId);

    setState(() {
      _isLikingPost = false;
    });

    if (!success) {
      _showSnackBar('Failed to like post. Please try again.');
    }
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final currentUserId = userProvider.currentUser?.uuid ?? '';

    return Scaffold(
      appBar: AppBar(title: Text('Blog')),
      body: Consumer<BlogProvider>(
        builder: (context, blogProvider, child) {
          final selectedPost = blogProvider.selectedPost;

          if (selectedPost == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No blog post selected'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final isPostLiked = selectedPost.likers.any(
            (liker) => liker.uuid == currentUserId,
          );

          final List<Widget> carouselItems = [
            Container(
              decoration: BoxDecoration(color: Colors.red.withAlpha(0)),
              child: Image.network(
                selectedPost.coverImage.link,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    ),
                  );
                },
              ),
            ),
          ];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ListView(
              children: [
                FadingCarousel(height: 180, children: carouselItems),
                SizedBox(height: 20),
                Text(
                  selectedPost.title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: wawuColors.primary.withAlpha(40),
                  ),
                  child: Text(
                    selectedPost.content.replaceAll(RegExp(r'<[^>]*>'), ''),
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'By ${selectedPost.authorName} • ${selectedPost.formattedDate}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10.0,
                  children: [
                    GestureDetector(
                      onTap: () => _handleLikePost(selectedPost.uuid),
                      child: Container(
                        width: 60,
                        height: 25,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color:
                              isPostLiked
                                  ? wawuColors.primary.withAlpha(150)
                                  : wawuColors.primary.withAlpha(70),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _isLikingPost
                                ? SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1,
                                    color: wawuColors.primary,
                                  ),
                                )
                                : Icon(
                                  isPostLiked
                                      ? Icons.thumb_up_alt
                                      : Icons.thumb_up_alt_outlined,
                                  size: 10,
                                  color: wawuColors.primary,
                                ),
                            Text(
                              _formatCount(selectedPost.likers.length),
                              style: TextStyle(
                                fontSize: 11,
                                color: wawuColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 25,
                      decoration: BoxDecoration(
                        color: wawuColors.primary.withAlpha(70),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mode_comment,
                            size: 10,
                            color: wawuColors.primary,
                          ),
                          Text(
                            _formatCount(selectedPost.comments.length),
                            style: TextStyle(
                              fontSize: 11,
                              color: wawuColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                CustomIntroText(
                  text: 'Comments (${selectedPost.comments.length})',
                ),
                SizedBox(height: 10),
                if (selectedPost.comments.isEmpty)
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No comments yet. Be the first to comment!',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  )
                else
                  ...selectedPost.comments.map((comment) {
                    return BlogCommentWidget(
                      comment: comment,
                      postId: selectedPost.uuid,
                      isTopLevel: true,
                      onLike: (commentId) async {
                        final success = await blogProvider.toggleLikeComment(
                          selectedPost.uuid,
                          commentId,
                        );
                        if (success) {
                          // Always refresh the post to ensure up-to-date comment like state
                          await blogProvider.fetchPostById(selectedPost.uuid);
                        } else {
                          _showSnackBar(
                            'Failed to like comment. Please try again.',
                          );
                        }
                        return success;
                      },
                      onReply: (commentId, reply) async {
                        final newReply = await blogProvider.addReply(
                          selectedPost.uuid,
                          commentId,
                          reply,
                        );
                        if (newReply == null) {
                          _showSnackBar(
                            'Failed to add reply. Please try again.',
                          );
                        } else {
                          _showSnackBar(
                            'Reply added successfully!',
                            isError: false,
                          );
                        }
                        return newReply != null;
                      },
                    );
                  }),
                SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      bottomSheet: _buildBottomSheet(),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.only(
        top: 10.0,
        bottom: 15.0,
        left: 10.0,
        right: 10.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: wawuColors.buttonSecondary.withAlpha(20),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: Colors.transparent, width: 1),
              ),
              padding: EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 0.0),
              child: TextField(
                controller: _commentController,
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  hintStyle: TextStyle(
                    color: Color.fromARGB(255, 201, 201, 201),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _isSubmittingComment ? null : _submitComment,
            icon:
                _isSubmittingComment
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: wawuColors.purpleDarkContainer,
                      ),
                    )
                    : Icon(Icons.send, color: wawuColors.purpleDarkContainer),
          ),
        ],
      ),
    );
  }
}

class BlogCommentWidget extends StatefulWidget {
  final BlogComment comment;
  final String postId;
  final bool isTopLevel;
  final Future<bool> Function(int commentId) onLike;
  final Future<bool> Function(int commentId, String reply) onReply;

  const BlogCommentWidget({
    super.key,
    required this.comment,
    required this.postId,
    required this.isTopLevel,
    required this.onLike,
    required this.onReply,
  });

  @override
  State<BlogCommentWidget> createState() => _BlogCommentWidgetState();
}

class _BlogCommentWidgetState extends State<BlogCommentWidget> {
  bool _isLiking = false;
  bool _showReplyField = false;
  bool _isSubmittingReply = false;
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _handleLike() async {
    if (_isLiking) return;

    setState(() {
      _isLiking = true;
    });

    await widget.onLike(widget.comment.id);

    setState(() {
      _isLiking = false;
    });
  }

  Future<void> _handleReply() async {
    final reply = _replyController.text.trim();
    if (reply.isEmpty) return;

    setState(() {
      _isSubmittingReply = true;
    });

    final success = await widget.onReply(widget.comment.id, reply);

    setState(() {
      _isSubmittingReply = false;
    });

    if (success) {
      _replyController.clear();
      setState(() {
        _showReplyField = false;
      });
    }
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  BlogComment? _findCommentById(List<BlogComment> comments, int id) {
    for (final comment in comments) {
      if (comment.id == id) return comment;
      final sub = _findCommentById(comment.subComments, id);
      if (sub != null) return sub;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BlogProvider>(
      builder: (context, blogProvider, child) {
        final selectedPost = blogProvider.selectedPost;
        BlogComment currentComment = widget.comment;
        if (selectedPost != null) {
          final found = _findCommentById(selectedPost.comments, widget.comment.id);
          if (found != null) currentComment = found;
        }
        final userProvider = context.watch<UserProvider>();
        final currentUserId = userProvider.currentUser?.uuid ?? '';
        final isCommentLiked = currentComment.likers.any(
          (liker) => liker.uuid == currentUserId,
        );

        return Container(
          padding: EdgeInsets.symmetric(vertical: 15.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: wawuColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child:
                        currentComment.commentedBy.profilePicture != null
                            ? ClipOval(
                              child: Image.network(
                                currentComment.commentedBy.profilePicture!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 20,
                                  );
                                },
                              ),
                            )
                            : Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${currentComment.commentedBy.firstName ?? ''} ${currentComment.commentedBy.lastName ?? ''}'
                                  .trim(),
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _formatTime(currentComment.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Text(
                          currentComment.content,
                          style: TextStyle(fontSize: 11),
                        ),
                        if (widget.isTopLevel) ...[
                          SizedBox(height: 10),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _handleLike,
                                child: Row(
                                  children: [
                                    _isLiking
                                        ? SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1,
                                            color: wawuColors.primary,
                                          ),
                                        )
                                        : Icon(
                                          isCommentLiked
                                              ? Icons.thumb_up_alt
                                              : Icons.thumb_up_alt_outlined,
                                          size: 12,
                                          color:
                                              isCommentLiked
                                                  ? wawuColors.primary
                                                  : Colors.grey[600],
                                        ),
                                    SizedBox(width: 5),
                                    Text(
                                      _formatCount(
                                        currentComment.likers.length,
                                      ),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color:
                                            isCommentLiked
                                                ? wawuColors.primary
                                                : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 15),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showReplyField = !_showReplyField;
                                  });
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.reply,
                                      size: 12,
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Reply',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_showReplyField)
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: TextField(
                                        controller: _replyController,
                                        decoration: InputDecoration(
                                          hintText: 'Write a reply...',
                                          border: InputBorder.none,
                                          hintStyle: TextStyle(fontSize: 12),
                                        ),
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  GestureDetector(
                                    onTap:
                                        _isSubmittingReply
                                            ? null
                                            : _handleReply,
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: wawuColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child:
                                          _isSubmittingReply
                                              ? SizedBox(
                                                width: 12,
                                                height: 12,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 1,
                                                      color: Colors.white,
                                                    ),
                                              )
                                              : Icon(
                                                Icons.send,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (currentComment.subComments.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(left: 50, top: 10),
                  child: Column(
                    children:
                        currentComment.subComments.map((subComment) {
                          return BlogCommentWidget(
                            comment: subComment,
                            postId: widget.postId,
                            isTopLevel: false,
                            onLike: widget.onLike,
                            onReply: widget.onReply,
                          );
                        }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
