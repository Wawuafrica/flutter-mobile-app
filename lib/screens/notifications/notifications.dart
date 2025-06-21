import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/notification_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
// import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/notifications_card/notifications_card.dart';

class Notifications extends StatelessWidget {
  const Notifications({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        // actions: [
        //   Consumer<UserProvider>(
        //     builder: (context, userProvider, child) {
        //       return TextButton(
        //         onPressed: userProvider.currentUser?.uuid != null
        //             ? () async {
        //                 await Provider.of<NotificationProvider>(context, listen: false)
        //                     .markAllAsRead(userProvider.currentUser!.uuid);
        //               }
        //             : null,
        //         child: const Text(
        //           'Mark all as read',
        //           style: TextStyle(color: wawuColors.primary, fontWeight: FontWeight.w300, fontSize: 12),
        //         ),
        //       );
        //     },
        //   ),
        // ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.currentUser?.uuid == null) {
            return const Center(
              child: Text('Please log in to view notifications'),
            );
          }

          return Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.notifications.isEmpty && !provider.hasMore) {
                return const Center(child: Text('No notifications found'));
              }

              if (provider.notifications.isEmpty) {
                provider.fetchNotifications(userProvider.currentUser!.uuid);
                return const Center(child: CircularProgressIndicator());
              }

              return RefreshIndicator(
                onRefresh:
                    () => provider.fetchNotifications(
                      userProvider.currentUser!.uuid,
                    ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ListView.builder(
                    itemCount:
                        provider.notifications.length +
                        (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.notifications.length &&
                          provider.hasMore) {
                        provider.fetchNotifications(
                          userProvider.currentUser!.uuid,
                          loadMore: true,
                        );
                        return const Center(child: CircularProgressIndicator());
                      }
                      final notification = provider.notifications[index];
                      return NotificationsCard(notification: notification);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
