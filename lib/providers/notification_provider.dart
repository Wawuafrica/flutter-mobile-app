import 'dart:convert';
import '../models/notification.dart';
import '../providers/base_provider.dart';
import '../services/api_service.dart';
import '../services/pusher_service.dart';

/// NotificationProvider manages user notifications state.
///
/// This provider handles:
/// - Fetching user notifications
/// - Marking notifications as read
/// - Receiving real-time notification updates via Pusher
/// - Tracking unread notification count
class NotificationProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;

  List<Notification> _notifications = [];
  bool _isSubscribedToGeneralChannel = false;

  // Getters
  List<Notification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider({ApiService? apiService, PusherService? pusherService})
    : _apiService = apiService ?? ApiService(),
      _pusherService = pusherService ?? PusherService();

  /// Fetches notifications for a user
  Future<List<Notification>> fetchNotifications(String userId) async {
    try {
      // Get notifications with pagination
      final response = await _apiService.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {
          'page': 1, // Start with first page
          'per_page': 20, // Fetch 20 notifications at a time
        },
      );

      if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> notificationsJson = response['data'] as List<dynamic>;
        final List<Notification> notifications =
            notificationsJson
                .map(
                  (json) => Notification.fromJson(json as Map<String, dynamic>),
                )
                .toList();

        // Sort notifications by timestamp, newest first
        notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        _notifications = notifications;

        // Subscribe to notifications channel if not already subscribed
        if (!_isSubscribedToGeneralChannel) {
          await _subscribeToNotificationsChannel(userId);
        }

        return notifications;
      } else {
        print('Invalid response format from notifications endpoint');
        return [];
      }
    } catch (e) {
      print('Failed to fetch notifications: $e');
      return [];
    }
  }

  /// Marks a notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      // Use the correct endpoint for marking a notification as read
      await _apiService.post<Map<String, dynamic>>(
        '/notifications/$notificationId/read',
        data: {},
      );

      // Update local notification to show as read
      _notifications =
          _notifications.map((notification) {
            if (notification.id == notificationId) {
              return notification.markAsRead();
            }
            return notification;
          }).toList();
      
      notifyListeners(); // Notify UI about the change

      return true;
    } catch (e) {
      print('Failed to mark notification as read: $e');
      return false;
    }
  }

  /// Marks all notifications as read
  Future<bool> markAllAsRead(String userId) async {
    try {
      // Use the correct endpoint for marking all notifications as read
      await _apiService.post<Map<String, dynamic>>(
        '/notifications/read-all',
        data: {},
      );

      // Update all local notifications to show as read
      _notifications =
          _notifications
              .map((notification) => notification.markAsRead())
              .toList();
              
      notifyListeners(); // Notify UI about the change

      return true;
    } catch (e) {
      print('Failed to mark all notifications as read: $e');
      return false;
    }
  }

  /// Deletes a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      // Use the correct endpoint for deleting a notification
      await _apiService.delete<Map<String, dynamic>>(
        '/notifications/$notificationId',
      );

      // Remove notification from local list
      _notifications.removeWhere(
        (notification) => notification.id == notificationId,
      );
      
      notifyListeners(); // Notify UI about the change

      return true;
    } catch (e) {
      print('Failed to delete notification: $e');
      return false;
    }
  }

  /// Subscribes to notification channel for real-time updates
  Future<void> _subscribeToNotificationsChannel(String userId) async {
    // Use the notifications channel as specified in the API document
    const channelName = 'notifications';

    try {
      final channel = await _pusherService.subscribeToChannel(channelName);
      if (channel != null) {
        _isSubscribedToGeneralChannel = true;

        // Bind to new notification events
        _pusherService.bindToEvent(channelName, 'NotificationCreated', (data) async {
          if (data is String) {
            final jsonData = jsonDecode(data) as Map<String, dynamic>;
          
            // Assuming the notification object is directly in the data payload based on the previous implementation
             final notification = Notification.fromJson(jsonData);

            // Only add if it's for this user (Requires user ID in notification payload or context)
            // For now, assuming all events on this channel are relevant or the model handles it.
            // If filtering by user ID is needed, the Notification model or payload structure must support it.
            // Assuming notification object has a userId field:
             // if (notification.userId == userId) {
              // Add notification to list and sort
              _notifications.add(notification);
              _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              notifyListeners();
             // }
          }
        });

        // Bind to notification read events - Event name is not explicitly in the provided list, keeping previous binding logic
        _pusherService.bindToEvent(channelName, 'NotificationRead', (
        data,
      ) async {
        if (data is String) {
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          
           // Assuming the event payload contains notification_id or the full notification
           // If payload contains notification_id:
           if (jsonData.containsKey('notification_id')) {
              final String notificationId = jsonData['notification_id'] as String;
              // Find and update the notification locally
               final index = _notifications.indexWhere((n) => n.id == notificationId);
               if(index != -1) {
                 _notifications[index] = _notifications[index].markAsRead();
                 notifyListeners();
               }
           } else if (jsonData.containsKey('notification') && jsonData['notification'] is Map<String, dynamic>) {
              // If payload contains the full notification object
               final readNotificationData = jsonData['notification'] as Map<String, dynamic>;
               final String notificationId = readNotificationData['uuid'] as String;
               final index = _notifications.indexWhere((n) => n.id == notificationId);
               if(index != -1) {
                 _notifications[index] = Notification.fromJson(readNotificationData); // Update with the new object
                 notifyListeners();
               }
           } else {
             print('NotificationRead event data missing notification_id or notification object');
           }
        }
      });

      // Bind to all notifications read events - Event name is not explicitly in the provided list, keeping previous binding logic
      _pusherService.bindToEvent(channelName, 'AllNotificationsRead', (
        data,
      ) async {
        if (data is String) {
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          
          // Check if this is for our user (Requires user ID in payload)
          if (jsonData.containsKey('user_id') && jsonData['user_id'] == userId) {
            // Mark all notifications as read
            _notifications =
                _notifications
                    .map((notification) => notification.markAsRead())
                    .toList();

            notifyListeners();
          }
        }
      });

      // Bind to notification delete events - Event name is not explicitly in the provided list, keeping previous binding logic
      _pusherService.bindToEvent(channelName, 'NotificationDeleted', (
        data,
      ) async {
        if (data is String) {
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          
          // Assuming the event payload contains notification_id or the full notification
           // If payload contains notification_id:
           if (jsonData.containsKey('notification_id')) {
              final String notificationId = jsonData['notification_id'] as String;
              // Remove notification from list
              _notifications.removeWhere(
                (notification) => notification.id == notificationId,
              );
               notifyListeners();
           } else if (jsonData.containsKey('notification') && jsonData['notification'] is Map<String, dynamic>) {
               // If payload contains the full notification object
               final deleteData = jsonData['notification'] as Map<String, dynamic>;
               final String notificationId = deleteData['uuid'] as String;
                _notifications.removeWhere(
                (notification) => notification.id == notificationId,
              );
               notifyListeners();
           } else {
             print('NotificationDeleted event data missing notification_id or notification object');
           }
        }
      });
    }
  } catch (e) {
    print('Failed to subscribe to user notifications: $e');
  }
}

  /// Clears all notification data
  void clearAll() {
    _notifications = [];
    _isSubscribedToGeneralChannel = false;
    resetState();
  }

  @override
  void dispose() {
    if (_isSubscribedToGeneralChannel) {
      // Unsubscribe from the general notifications channel
      _pusherService.unsubscribeFromChannel('notifications');
    }
    // No specific notification channels mentioned in the new data, so no need to unsubscribe from those.
    super.dispose();
  }
}
