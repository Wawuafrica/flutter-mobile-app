import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/notification_provider.dart';
import 'notifications_helper.dart'; // Import the helper we created

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({Key? key}) : super(key: key);

  @override
  _NotificationTestPageState createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  @override
  void initState() {
    super.initState();
    TestNotificationHelper.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: Colors.blue[600],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Notifications: ${notificationProvider.notifications.length}',
                        ),
                        Text(
                          'Unread Count: ${notificationProvider.unreadCount}',
                        ),
                        Text(
                          'Provider State: ${notificationProvider.isLoading
                              ? "Loading"
                              : notificationProvider.hasError
                              ? "Error"
                              : "Ready"}',
                        ),
                        if (notificationProvider.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Error: ${notificationProvider.errorMessage}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Test Buttons
                const Text(
                  'Local Notification Tests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: () async {
                    await TestNotificationHelper.showTestNotification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Test notification sent!')),
                    );
                  },
                  icon: const Icon(Icons.notifications),
                  label: const Text('Show Single Test Notification'),
                ),
                const SizedBox(height: 8),

                ElevatedButton.icon(
                  onPressed: () async {
                    await TestNotificationHelper.showAllTestNotificationTypes();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Multiple test notifications scheduled!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Show All Notification Types'),
                ),
                const SizedBox(height: 8),

                ElevatedButton.icon(
                  onPressed: () async {
                    await TestNotificationHelper.showScheduledTestNotification(
                      delay: const Duration(seconds: 10),
                      title: 'Scheduled Test',
                      body: 'This notification was scheduled 10 seconds ago!',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification scheduled for 10 seconds!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.schedule),
                  label: const Text('Schedule Notification (10s)'),
                ),
                const SizedBox(height: 8),

                ElevatedButton.icon(
                  onPressed: () async {
                    await TestNotificationHelper.cancelAllTestNotifications();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications cancelled!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel All Notifications'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Provider Tests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: () async {
                    // Simulate adding a notification to the provider
                    final testNotification =
                        TestNotificationHelper.getRandomTestNotification();

                    // Add to the internal list (this simulates receiving from Pusher)
                    notificationProvider.notifications.add(testNotification);

                    // Trigger a rebuild
                    notificationProvider.notifyListeners();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Added test notification: ${testNotification.data['message']}',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Test Notification to Provider'),
                ),
                const SizedBox(height: 8),

                ElevatedButton.icon(
                  onPressed: () async {
                    // Load sample notifications into provider
                    final sampleNotifications =
                        TestNotificationHelper.getSampleNotifications();
                    notificationProvider.notifications.clear();
                    notificationProvider.notifications.addAll(
                      sampleNotifications,
                    );
                    notificationProvider.notifyListeners();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Loaded ${sampleNotifications.length} sample notifications',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('Load Sample Data'),
                ),
                const SizedBox(height: 8),

                ElevatedButton.icon(
                  onPressed: () {
                    notificationProvider.clearAll();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cleared all provider data'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Provider Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Permission Tests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: () async {
                    final enabled =
                        await TestNotificationHelper.areNotificationsEnabled();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          enabled
                              ? 'Notifications are enabled!'
                              : 'Notifications are disabled!',
                        ),
                        backgroundColor: enabled ? Colors.green : Colors.red,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Check Notification Permissions'),
                ),

                const SizedBox(height: 24),

                // Current Notifications List
                if (notificationProvider.notifications.isNotEmpty) ...[
                  Text(
                    'Current Notifications (${notificationProvider.notifications.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...notificationProvider.notifications.take(5).map((
                    notification,
                  ) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading:
                            notification.isRead
                                ? const Icon(
                                  Icons.mark_email_read,
                                  color: Colors.grey,
                                )
                                : const Icon(
                                  Icons.mark_email_unread,
                                  color: Colors.blue,
                                ),
                        title: Text(
                          notification.data['message'] ?? 'No message',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Type: ${notification.type.split('\\').last}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            notificationProvider.notifications.removeWhere(
                              (n) => n.id == notification.id,
                            );
                            notificationProvider.notifyListeners();
                          },
                        ),
                      ),
                    );
                  }).toList(),
                  if (notificationProvider.notifications.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '... and ${notificationProvider.notifications.length - 5} more',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
