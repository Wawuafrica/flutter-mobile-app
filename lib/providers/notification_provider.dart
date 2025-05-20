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
        if (!_isSubscribed) {
          await _subscribeToUserNotifications(userId);
        }

        return notifications;
      } else {
        throw Exception('Invalid response format from notifications endpoint');
      }
    }, errorMessage: 'Failed to fetch notifications');

    return result ?? [];
  }

  /// Marks a notification as read
  Future<bool> markAsRead(String notificationId) async {
    final result = await handleAsync(() async {
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
    }, errorMessage: 'Failed to mark notification as read');

    return result ?? false;
  }

  /// Marks all notifications as read
  Future<bool> markAllAsRead(String userId) async {
    final result = await handleAsync(() async {
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
    }, errorMessage: 'Failed to mark all notifications as read');

    return result ?? false;
  }

  /// Deletes a notification
  Future<bool> deleteNotification(String notificationId) async {
    final result = await handleAsync(() async {
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
    }, errorMessage: 'Failed to delete notification');

    return result ?? false;
  }

  /// Subscribes to notification channel for real-time updates
  Future<void> _subscribeToUserNotifications(String userId) async {
    // Use the notifications channel as specified in the API document
    final channelName = 'notifications';

    final channel = await _pusherService.subscribeToChannel(channelName);
    if (channel != null) {
      _isSubscribed = true;

      // Bind to new notification events
      _pusherService.bindToEvent(channelName, 'NotificationCreated', (data) async {
        if (data is String) {
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          
          if (jsonData.containsKey('notification') && 
              jsonData['notification'] is Map<String, dynamic>) {
            
            final notificationData = jsonData['notification'] as Map<String, dynamic>;
            final notification = Notification.fromJson(notificationData);

            // Only add if it's for this user
            if (notification.userId == userId) {
              // Add notification to list and sort
              _notifications.add(notification);
              _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

              notifyListeners();
            }
          }
        }
      });

      // Bind to notification read events
      _pusherService.bindToEvent(channelName, 'NotificationRead', (
        data,
      ) async {
        if (data is String) {
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          
          if (jsonData.containsKey('notification') && 
              jsonData['notification'] is Map<String, dynamic>) {
            
            final readData = jsonData['notification'] as Map<String, dynamic>;
            final String notificationId = readData['uuid'] as String;

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
        }
      });

      // Bind to all notifications read events
      _pusherService.bindToEvent(channelName, 'AllNotificationsRead', (
        data,
      ) async {
        if (data is String) {
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          
          // Check if this is for our user
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

      // Bind to notification delete events
      _pusherService.bindToEvent(channelName, 'NotificationDeleted', (
        data,
      ) async {
        if (data is String) {
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          
          if (jsonData.containsKey('notification') && 
              jsonData['notification'] is Map<String, dynamic>) {
            
            final deleteData = jsonData['notification'] as Map<String, dynamic>;
            final String notificationId = deleteData['uuid'] as String;

            // Remove notification from list
            _notifications.removeWhere(
              (notification) => notification.id == notificationId,
            );

            notifyListeners();
          }
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
