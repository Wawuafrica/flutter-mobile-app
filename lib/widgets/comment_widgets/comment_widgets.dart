import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wawu_mobile/models/wawu_africa_social.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wawu_mobile/utils/constants/colors.dart';

/// A text input field and send button for creating new comments.
class CommentInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSendPressed;
  final FocusNode? focusNode;

  const CommentInputWidget({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSendPressed,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: 8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
            ),
          ),
          isLoading
              ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
              : IconButton(
                icon: const Icon(Icons.send),
                onPressed: onSendPressed,
                color: Theme.of(context).primaryColor,
              ),
        ],
      ),
    );
  }
}

/// A reusable button for liking content or comments.
class LikeButton extends StatelessWidget {
  final int likeCount;
  final bool isLiked;
  final VoidCallback onPressed;

  const LikeButton({
    super.key,
    required this.likeCount,
    required this.isLiked,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? wawuColors.primary : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              likeCount.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays a single comment and its replies.
class CommentWidget extends StatelessWidget {
  final Comment comment;
  final VoidCallback onLikePressed;
  final ValueChanged<Comment> onReplyPressed;
  final VoidCallback onDeletePressed;
  final int likeCount;
  final bool isLiked;
  final bool isAuthor; // Takes a boolean flag directly

  const CommentWidget({
    super.key,
    required this.comment,
    required this.onLikePressed,
    required this.onReplyPressed,
    required this.onDeletePressed,
    required this.likeCount,
    required this.isLiked,
    required this.isAuthor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            backgroundImage:
                comment.user.profileImage != null
                    ? CachedNetworkImageProvider(comment.user.profileImage!)
                    : null,
            child:
                comment.user.profileImage == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(comment.comment),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      timeago.format(comment.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    LikeButton(
                      likeCount: likeCount,
                      isLiked: isLiked,
                      onPressed: onLikePressed,
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => onReplyPressed(comment),
                      child: const Text(
                        'Reply',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isAuthor)
            PopupMenuButton<String>(
              padding: const EdgeInsets.all(0),
              icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
              onSelected: (value) {
                if (value == 'delete') {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('Delete Comment'),
                        content: const Text(
                          'Are you sure you want to delete this comment? This action cannot be undone.',
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                          TextButton(
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              onDeletePressed();
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
            ),
        ],
      ),
    );
  }
}
