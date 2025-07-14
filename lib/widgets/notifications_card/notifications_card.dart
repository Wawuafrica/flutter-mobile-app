import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/notification.dart';
import 'package:wawu_mobile/providers/notification_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class NotificationsCard extends StatefulWidget {
  final NotificationModel notification;

  const NotificationsCard({super.key, required this.notification});

  static const Map<String, String> _notificationTitles = {
    'App\\Notifications\\UserSubscribed': 'Subscription Update',
    'App\\Notifications\\UserLogin': 'Login Alert',
    'App\\Notifications\\PaymentSuccessful': 'Payment Success',
    'App\\Notifications\\PaymentDeclined': 'Payment Declined',
    'App\\Notifications\\NewMessage': 'New Message',
  };

  @override
  State<NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends State<NotificationsCard> {
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
    return NotificationsCard._notificationTitles[type] ?? 'Notification';
  }

  void _showNotificationDetails(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              _getNotificationTitle(widget.notification.type),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.notification.data['message']?.toString() ??
                        'No message',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatTimestamp(widget.notification.timestamp),
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    bool isLoading = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            GestureDetector(
              onTap: () {
                _showNotificationDetails(context);
                if (!widget.notification.isRead &&
                    userProvider.currentUser?.uuid != null) {
                  setState(() => isLoading = true);
                  notificationProvider.markAsRead(widget.notification.id).then((
                    _,
                  ) {
                    if (mounted) {
                      setState(() => isLoading = false);
                    }
                  });
                }
              },
              child: Container(
                width: double.infinity,
                height: 110,
                decoration: BoxDecoration(
                  color:
                      widget.notification.isRead
                          ? wawuColors.primary.withAlpha(15)
                          : Colors.transparent,
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
                            _getNotificationTitle(widget.notification.type),
                            style: TextStyle(
                              fontWeight:
                                  widget.notification.isRead
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!widget.notification.isRead && !isLoading)
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.purple,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(widget.notification.timestamp),
                              style: const TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        widget.notification.data['message']?.toString() ??
                            'No message',
                        style: const TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
