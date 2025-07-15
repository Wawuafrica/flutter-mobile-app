import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/notification_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/widgets/notifications_card/notifications_card.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize notifications only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  Future<void> _initializeNotifications() async {
    if (_hasInitialized) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    if (userProvider.currentUser?.uuid != null) {
      _hasInitialized = true;
      await notificationProvider.fetchNotifications(
        userProvider.currentUser!.uuid,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        // Uncomment this section when you want to enable "Mark all as read"
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
              // Show loading indicator only when initially loading
              if (!_hasInitialized && provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // Show empty state
              if (provider.notifications.isEmpty && !provider.hasMore) {
                return const Center(child: Text('No notifications found'));
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
                        // Load more notifications when reaching the end
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!provider.isLoading) {
                            provider.fetchNotifications(
                              userProvider.currentUser!.uuid,
                              loadMore: true,
                            );
                          }
                        });
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
