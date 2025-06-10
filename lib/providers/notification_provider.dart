import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wawu_mobile/models/notification.dart';
import 'package:wawu_mobile/services/api_service.dart';
import 'package:wawu_mobile/services/pusher_service.dart';
import 'package:wawu_mobile/providers/base_provider.dart';
import 'package:logger/logger.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'dart:convert';

class NotificationProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();

  List<NotificationModel> _notifications = [];
  bool _isSubscribedToGeneralChannel = false;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _currentUserId; // Store current user ID for filtering

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasMore => _hasMore;

  NotificationProvider({ApiService? apiService, PusherService? pusherService})
    : _apiService = apiService ?? ApiService(),
      _pusherService = pusherService ?? PusherService() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _notificationsPlugin.initialize(initializationSettings);
      _logger.i(
        'NotificationProvider: Local notifications initialized successfully',
      );
    } catch (e) {
      _logger.e(
        'NotificationProvider: Failed to initialize local notifications: $e',
      );
    }
  }

  Future<void> _showPushNotification(NotificationModel notification) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'notification_channel',
        'Notifications',
        importance: Importance.high,
        priority: Priority.high,
      );
      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        notification.id.hashCode,
        _getNotificationTitle(notification.type),
        notification.data['message']?.toString() ?? 'New notification',
        platformDetails,
      );

      _logger.i(
        'NotificationProvider: Local notification shown for ${notification.type}',
      );
    } catch (e) {
      _logger.e('NotificationProvider: Failed to show local notification: $e');
    }
  }

  String _getNotificationTitle(String type) {
    const titles = {
      'App\\Notifications\\UserSubscribed': 'Subscription Update',
      'App\\Notifications\\UserLogin': 'Login Alert',
      'App\\Notifications\\PaymentSuccessful': 'Payment Success',
      'App\\Notifications\\PaymentDeclined': 'Payment Declined',
      'App\\Notifications\\NewMessage': 'New Message',
      'App\\Notifications\\NewComment': 'New Comment',
      'App\\Notifications\\NewLike': 'New Like',
      'App\\Notifications\\NewFollow': 'New Follower',
      'App\\Notifications\\PostApproved': 'Post Approved',
      'App\\Notifications\\PostRejected': 'Post Rejected',
    };
    return titles[type] ?? 'Notification';
  }

  Future<List<NotificationModel>> fetchNotifications(
    String userId, {
    bool loadMore = false,
  }) async {
    if (_isLoadingMore && loadMore) return _notifications;

    try {
      _isLoadingMore = loadMore;
      _currentUserId = userId; // Store current user ID

      if (!loadMore) {
        _currentPage = 1;
        _notifications = [];
      } else {
        _currentPage++;
      }

      _logger.i(
        'NotificationProvider: Fetching notifications for user $userId, page $_currentPage',
      );

      // Fetch both read and unread notifications
      final endpoints = ['/notifications/unread', '/notifications/read'];
      List<NotificationModel> allNotifications = [];

      for (final endpoint in endpoints) {
        try {
          final response = await _apiService.get<Map<String, dynamic>>(
            endpoint,
            queryParameters: {'page': _currentPage, 'per_page': 20},
          );

          if (response['statusCode'] == 200 &&
              response['data']['data'] is List) {
            final List<dynamic> notificationsJson =
                response['data']['data'] as List<dynamic>;
            final newNotifications =
                notificationsJson
                    .map(
                      (json) => NotificationModel.fromJson(
                        json as Map<String, dynamic>,
                      ),
                    )
                    .toList();
            allNotifications.addAll(newNotifications);
            _logger.d(
              'NotificationProvider: Fetched ${newNotifications.length} notifications from $endpoint',
            );
          } else {
            _logger.w(
              'NotificationProvider: Invalid response format from $endpoint',
            );
          }
        } catch (e) {
          _logger.e('NotificationProvider: Error fetching from $endpoint: $e');
        }
      }

      _hasMore = allNotifications.length >= 20;
      _notifications =
          loadMore
              ? [..._notifications, ...allNotifications]
              : allNotifications;
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Subscribe to notifications channel if not already subscribed
      if (!_isSubscribedToGeneralChannel) {
        await _subscribeToNotificationsChannel(userId);
      }

      _logger.i(
        'NotificationProvider: Total notifications loaded: ${_notifications.length}',
      );
      notifyListeners();
      return _notifications;
    } catch (e) {
      _logger.e('NotificationProvider: Failed to fetch notifications: $e');
      return [];
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _apiService.patch<Map<String, dynamic>>(
        '/notifications/$notificationId/mark-as-read',
        data: {},
      );

      if (response['statusCode'] == 200) {
        _notifications =
            _notifications.map((notification) {
              if (notification.id == notificationId) {
                return notification.markAsRead();
              }
              return notification;
            }).toList();

        _logger.i(
          'NotificationProvider: Marked notification $notificationId as read',
        );
        notifyListeners();
        return true;
      }

      _logger.w(
        'NotificationProvider: Failed to mark notification as read - Status: ${response['statusCode']}',
      );
      return false;
    } catch (e) {
      _logger.e(
        'NotificationProvider: Failed to mark notification as read: $e',
      );
      return false;
    }
  }

  Future<bool> markAllAsRead(String userId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/notifications/mark-all-as-read',
        data: {},
      );

      if (response['statusCode'] == 200) {
        _notifications =
            _notifications
                .map((notification) => notification.markAsRead())
                .toList();

        _logger.i(
          'NotificationProvider: Marked all notifications as read for user $userId',
        );
        notifyListeners();
        return true;
      }

      _logger.w(
        'NotificationProvider: Failed to mark all notifications as read - Status: ${response['statusCode']}',
      );
      return false;
    } catch (e) {
      _logger.e(
        'NotificationProvider: Failed to mark all notifications as read: $e',
      );
      return false;
    }
  }

  Future<void> _subscribeToNotificationsChannel(String userId) async {
    if (!_pusherService.isInitialized) {
      _logger.w(
        'NotificationProvider: PusherService not initialized, cannot subscribe to notifications',
      );
      return;
    }

    const channelName = 'notifications';

    try {
      final success = await _pusherService.subscribeToChannel(channelName);
      if (success) {
        _isSubscribedToGeneralChannel = true;
        _logger.i(
          'NotificationProvider: Successfully subscribed to notifications channel',
        );

        // Bind to NotificationCreated event
        _pusherService.bindToEvent(channelName, 'NotificationCreated', (
          PusherEvent event,
        ) {
          _handleNotificationCreated(event, userId);
        });

        // Bind to NotificationRead event
        _pusherService.bindToEvent(channelName, 'NotificationRead', (
          PusherEvent event,
        ) {
          _handleNotificationRead(event, userId);
        });

        // Bind to AllNotificationsRead event
        _pusherService.bindToEvent(channelName, 'AllNotificationsRead', (
          PusherEvent event,
        ) {
          _handleAllNotificationsRead(event, userId);
        });

        // Bind to NotificationDeleted event
        _pusherService.bindToEvent(channelName, 'NotificationDeleted', (
          PusherEvent event,
        ) {
          _handleNotificationDeleted(event, userId);
        });

        _logger.i(
          'NotificationProvider: Successfully bound to all notification events',
        );
      } else {
        _logger.e(
          'NotificationProvider: Failed to subscribe to notifications channel',
        );
      }
    } catch (e) {
      _logger.e(
        'NotificationProvider: Failed to subscribe to notifications: $e',
      );
    }
  }

  void _handleNotificationCreated(PusherEvent event, String userId) async {
    try {
      if (event.data is! String) {
        _logger.w(
          'NotificationProvider: Invalid NotificationCreated event data. Expected String, got ${event.data.runtimeType}',
        );
        return;
      }

      final jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      final notification = NotificationModel.fromJson(jsonData);

      _logger.i(
        'NotificationProvider: Received NotificationCreated event for user ${notification.notifiableId}',
      );

      // Only add notification if it's for the current user
      if (notification.notifiableId.toString() == userId) {
        // Check if notification already exists to avoid duplicates
        final existingIndex = _notifications.indexWhere(
          (n) => n.id == notification.id,
        );
        if (existingIndex == -1) {
          _notifications.add(notification);
          _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          await _showPushNotification(notification);
          notifyListeners();

          _logger.i(
            'NotificationProvider: Added new notification ${notification.id} for current user',
          );
        } else {
          _logger.d(
            'NotificationProvider: Notification ${notification.id} already exists, skipping',
          );
        }
      }
    } catch (e) {
      _logger.e(
        'NotificationProvider: Error processing NotificationCreated event: $e',
      );
    }
  }

  void _handleNotificationRead(PusherEvent event, String userId) async {
    try {
      if (event.data is! String) {
        _logger.w(
          'NotificationProvider: Invalid NotificationRead event data. Expected String, got ${event.data.runtimeType}',
        );
        return;
      }

      final jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      final notificationId =
          jsonData['notification_id'] as String? ?? jsonData['id'] as String?;
      final eventUserId = jsonData['user_id']?.toString();

      _logger.i(
        'NotificationProvider: Received NotificationRead event for notification $notificationId',
      );

      // Only process if it's for the current user
      if (notificationId != null &&
          (eventUserId == null || eventUserId == userId)) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].markAsRead();
          notifyListeners();
          _logger.i(
            'NotificationProvider: Marked notification $notificationId as read via real-time event',
          );
        }
      }
    } catch (e) {
      _logger.e(
        'NotificationProvider: Error processing NotificationRead event: $e',
      );
    }
  }

  void _handleAllNotificationsRead(PusherEvent event, String userId) async {
    try {
      if (event.data is! String) {
        _logger.w(
          'NotificationProvider: Invalid AllNotificationsRead event data. Expected String, got ${event.data.runtimeType}',
        );
        return;
      }

      final jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      final eventUserId = jsonData['user_id']?.toString();

      _logger.i(
        'NotificationProvider: Received AllNotificationsRead event for user $eventUserId',
      );

      // Only process if it's for the current user
      if (eventUserId == userId) {
        _notifications =
            _notifications
                .map((notification) => notification.markAsRead())
                .toList();
        notifyListeners();
        _logger.i(
          'NotificationProvider: Marked all notifications as read via real-time event',
        );
      }
    } catch (e) {
      _logger.e(
        'NotificationProvider: Error processing AllNotificationsRead event: $e',
      );
    }
  }

  void _handleNotificationDeleted(PusherEvent event, String userId) async {
    try {
      if (event.data is! String) {
        _logger.w(
          'NotificationProvider: Invalid NotificationDeleted event data. Expected String, got ${event.data.runtimeType}',
        );
        return;
      }

      final jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      final notificationId =
          jsonData['notification_id'] as String? ?? jsonData['id'] as String?;
      final eventUserId = jsonData['user_id']?.toString();

      _logger.i(
        'NotificationProvider: Received NotificationDeleted event for notification $notificationId',
      );

      // Only process if it's for the current user
      if (notificationId != null &&
          (eventUserId == null || eventUserId == userId)) {
        final removedCount = _notifications.length;
        _notifications.removeWhere(
          (notification) => notification.id == notificationId,
        );

        if (_notifications.length < removedCount) {
          notifyListeners();
          _logger.i(
            'NotificationProvider: Removed notification $notificationId via real-time event',
          );
        }
      }
    } catch (e) {
      _logger.e(
        'NotificationProvider: Error processing NotificationDeleted event: $e',
      );
    }
  }

  // Method to delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        '/notifications/$notificationId',
      );

      if (response['statusCode'] == 200) {
        _notifications.removeWhere(
          (notification) => notification.id == notificationId,
        );

        _logger.i('NotificationProvider: Deleted notification $notificationId');
        notifyListeners();
        return true;
      }

      _logger.w(
        'NotificationProvider: Failed to delete notification - Status: ${response['statusCode']}',
      );
      return false;
    } catch (e) {
      _logger.e('NotificationProvider: Failed to delete notification: $e');
      return false;
    }
  }

  // Method to refresh notifications
  Future<void> refreshNotifications() async {
    if (_currentUserId != null) {
      await fetchNotifications(_currentUserId!, loadMore: false);
    }
  }

  // Method to load more notifications
  Future<void> loadMoreNotifications() async {
    if (_currentUserId != null && _hasMore && !_isLoadingMore) {
      await fetchNotifications(_currentUserId!, loadMore: true);
    }
  }

  void clearAll() {
    _notifications = [];
    _currentPage = 1;
    _hasMore = true;
    _isSubscribedToGeneralChannel = false;
    _currentUserId = null;
    _logger.i('NotificationProvider: Cleared all notifications data');
    notifyListeners();
  }

  // Method to unsubscribe from notifications (useful for logout)
  Future<void> unsubscribeFromNotifications() async {
    if (_isSubscribedToGeneralChannel) {
      await _pusherService.unsubscribeFromChannel('notifications');
      _isSubscribedToGeneralChannel = false;
      _logger.i(
        'NotificationProvider: Unsubscribed from notifications channel',
      );
    }
  }

  @override
  void dispose() {
    unsubscribeFromNotifications();
    _logger.i('NotificationProvider: Disposed');
    super.dispose();
  }
}
