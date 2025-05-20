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
  bool _isSubscribed = false;

  // Getters
  List<Notification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider({ApiService? apiService, PusherService? pusherService})
    : _apiService = apiService ?? ApiService(),
      _pusherService = pusherService ?? PusherService();

  /// Fetches notifications for a user
  Future<List<Notification>> fetchNotifications(String userId) async {
    final result = await handleAsync(() async {
      // TODO: Replace with actual endpoint
      final response = await _apiService.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {'user_id': userId},
      );

      final List<dynamic> notificationsJson =
          response['notifications'] as List<dynamic>;
      final List<Notification> notifications =
          notificationsJson
              .map(
                (json) => Notification.fromJson(json as Map<String, dynamic>),
              )
              .toList();

      // Sort notifications by timestamp, newest first
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _notifications = notifications;

      // Subscribe to user's notification channel if not already subscribed
      if (!_isSubscribed) {
        await _subscribeToUserNotifications(userId);
      }

      return notifications;
    }, errorMessage: 'Failed to fetch notifications');

    return result ?? [];
  }

  /// Marks a notification as read
  Future<bool> markAsRead(String notificationId) async {
    final result = await handleAsync(() async {
      // TODO: Replace with actual endpoint
      await _apiService.put<Map<String, dynamic>>(
        '/notifications/read',
        data: {'notification_id': notificationId},
      );

      // Update local notification to show as read
      _notifications =
          _notifications.map((notification) {
            if (notification.id == notificationId) {
              return notification.markAsRead();
            }
            return notification;
          }).toList();

      return true;
    }, errorMessage: 'Failed to mark notification as read');

    return result ?? false;
  }

  /// Marks all notifications as read
  Future<bool> markAllAsRead(String userId) async {
    final result = await handleAsync(() async {
      // TODO: Replace with actual endpoint
      await _apiService.put<Map<String, dynamic>>(
        '/notifications/read-all',
        data: {'user_id': userId},
      );

      // Update all local notifications to show as read
      _notifications =
          _notifications
              .map((notification) => notification.markAsRead())
              .toList();

      return true;
    }, errorMessage: 'Failed to mark all notifications as read');

    return result ?? false;
  }

  /// Deletes a notification
  Future<bool> deleteNotification(String notificationId) async {
    final result = await handleAsync(() async {
      // TODO: Replace with actual endpoint
      await _apiService.delete<Map<String, dynamic>>(
        '/notifications/$notificationId',
      );

      // Remove notification from local list
      _notifications.removeWhere(
        (notification) => notification.id == notificationId,
      );

      return true;
    }, errorMessage: 'Failed to delete notification');

    return result ?? false;
  }

  /// Subscribes to user's notification channel for real-time updates
  Future<void> _subscribeToUserNotifications(String userId) async {
    // Channel name pattern: 'user-notifications-{userId}'
    final channelName = 'user-notifications-$userId';

    final channel = await _pusherService.subscribeToChannel(channelName);
    if (channel != null) {
      _isSubscribed = true;

      // Bind to new notification events
      _pusherService.bindToEvent(channelName, 'new-notification', (data) async {
        if (data is String) {
          final notificationData = jsonDecode(data) as Map<String, dynamic>;
          final notification = Notification.fromJson(notificationData);

          // Add notification to list and sort
          _notifications.add(notification);
          _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          notifyListeners();
        }
      });

      // Bind to notification read events
      _pusherService.bindToEvent(channelName, 'notification-read', (
        data,
      ) async {
        if (data is String) {
          final readData = jsonDecode(data) as Map<String, dynamic>;
          final String notificationId = readData['notification_id'] as String;

          // Update notification read status
          _notifications =
              _notifications.map((notification) {
                if (notification.id == notificationId) {
                  return notification.markAsRead();
                }
                return notification;
              }).toList();

          notifyListeners();
        }
      });

      // Bind to all notifications read events
      _pusherService.bindToEvent(channelName, 'all-notifications-read', (
        data,
      ) async {
        // Mark all notifications as read
        _notifications =
            _notifications
                .map((notification) => notification.markAsRead())
                .toList();

        notifyListeners();
      });

      // Bind to notification delete events
      _pusherService.bindToEvent(channelName, 'notification-deleted', (
        data,
      ) async {
        if (data is String) {
          final deleteData = jsonDecode(data) as Map<String, dynamic>;
          final String notificationId = deleteData['notification_id'] as String;

          // Remove notification from list
          _notifications.removeWhere(
            (notification) => notification.id == notificationId,
          );

          notifyListeners();
        }
      });
    }
  }

  /// Clears all notification data
  void clearAll() {
    _notifications = [];
    _isSubscribed = false;
    resetState();
  }

  @override
  void dispose() {
    if (_isSubscribed) {
      // Unsubscribe from any notification channels
      _pusherService.disconnect();
    }
    super.dispose();
  }
}
