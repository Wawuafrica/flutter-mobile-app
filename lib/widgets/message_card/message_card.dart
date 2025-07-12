// widgets/message_card/message_card.dart
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wawu_mobile/models/conversation.dart';
import 'package:wawu_mobile/models/chat_user.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImage

class MessageCard extends StatelessWidget {
  final Conversation conversation;
  final String currentUserId;
  final ChatUser? recipient;
  final void Function()? onTap;
  final int unreadCount; // Added unreadCount as a parameter

  const MessageCard({
    super.key,
    required this.conversation,
    required this.currentUserId,
    this.recipient,
    this.onTap,
    required this.unreadCount, // Made unreadCount required
  });

  @override
  Widget build(BuildContext context) {
    // Get the other participant's name and avatar from recipient if available, otherwise from conversation
    final otherParticipant =
        recipient ??
        conversation.participants.firstWhere(
          (user) => user.id != currentUserId,
          orElse: () => ChatUser(id: '', name: 'Unknown', avatar: null),
        );

    // Get last message details
    final lastMessage = conversation.lastMessage;
    final lastMessageContent = lastMessage?.content ?? 'No messages yet';
    final lastMessageTime =
        lastMessage?.timestamp != null
            ? timeago.format(lastMessage!.timestamp)
            : '';

    // The unreadCount is now passed in as a parameter, no longer calculated here.
    // final unreadCount = conversation.messages
    //     .where((msg) => msg.senderId != currentUserId && !msg.isRead)
    //     .length;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 90,
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child:
                      otherParticipant.avatar != null &&
                              otherParticipant.avatar!.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: otherParticipant.avatar!,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  width: 50,
                                  height: 50,
                                  color: wawuColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Image.asset(
                                  'assets/images/other/avatar.webp',
                                  fit: BoxFit.cover,
                                ),
                          )
                          : Image.asset(
                            'assets/images/other/avatar.webp',
                            fit: BoxFit.cover,
                          ),
                ),
              ],
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        otherParticipant.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        lastMessageTime,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lastMessageContent,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: wawuColors.primary,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
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
