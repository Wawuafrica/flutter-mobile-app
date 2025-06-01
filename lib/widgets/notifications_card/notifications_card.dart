import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/notification.dart';
import 'package:wawu_mobile/providers/notification_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class NotificationsCard extends StatelessWidget {
  final NotificationModel notification;

  const NotificationsCard({super.key, required this.notification});

  static const Map<String, String> _notificationTitles = {
    'App\\Notifications\\UserSubscribed': 'Subscription Update',
    'App\\Notifications\\UserLogin': 'Login Alert',
    'App\\Notifications\\PaymentSuccessful': 'Payment Success',
    'App\\Notifications\\PaymentDeclined': 'Payment Declined',
    'App\\Notifications\\NewMessage': 'New Message',
  };

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Unknown time';
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }

  String _getNotificationTitle(String type) {
    return _notificationTitles[type] ?? 'Notification';
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    bool isLoading = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            GestureDetector(
              onTap: notification.isRead || isLoading || userProvider.currentUser?.uuid == null
                  ? null
                  : () async {
                      setState(() => isLoading = true);
                      await notificationProvider.markAsRead(notification.id);
                      setState(() => isLoading = false);
                    },
              child: Container(
                width: double.infinity,
                height: 110,
                decoration: BoxDecoration(
                  color: notification.isRead ? wawuColors.primary.withAlpha(15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color.fromARGB(255, 224, 224, 224),
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _getNotificationTitle(notification.type),
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w600,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!notification.isRead && !isLoading)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.purple,
                                ),
                              ),
                            if (isLoading)
                              const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(notification.timestamp),
                              style: const TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      notification.data['message']?.toString() ?? 'No message',
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }
}