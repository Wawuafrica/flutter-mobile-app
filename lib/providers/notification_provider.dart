import 'dart:async';
import 'dart:io';
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
      if (Platform.isAndroid) {
        final androidPlugin =
            _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            'notification_channel',
            'Notifications',
            description: 'Channel for app notifications',
            importance: Importance.high,
          ),
        );
        final granted = await androidPlugin?.requestNotificationsPermission();
        if (granted == null || !granted) {
          _logger.w(
            'NotificationProvider: Android notification permission not granted',
          );
          // No setError here as it's a permission issue, not a provider data error.
          return;
        }
      } else if (Platform.isIOS) {
        final iosPlugin =
            _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >();
        await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (
          NotificationResponse response,
        ) async {
          _logger.i('Notification tapped: ${response.payload}');
          // Handle notification tap (e.g., navigate to a specific screen)
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      _logger.i(
        'NotificationProvider: Local notifications initialized successfully',
      );
      // No setSuccess here as this is an internal initialization, not a primary data operation.
    } catch (e) {
      _logger.e(
        'NotificationProvider: Failed to initialize local notifications: $e',
      );
      // No setError here as this is an internal initialization, not a primary data operation.
    }
  }

  @pragma('vm:entry-point')
  void notificationTapBackground(NotificationResponse response) {
    // Handle background notification tap
    _logger.i('Background notification tapped: ${response.payload}');
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
      // No setError here as this is an internal display function.
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
    // Use BaseProvider's isLoading. If already loading for a primary operation, return.
    // _isLoadingMore is removed, so we check BaseProvider's isLoading.
    if (isLoading && loadMore) return _notifications;

    // Set loading state for the primary operation.
    // If loadMore is true, we are "loading more" but the main state is still "loading".
    // If loadMore is false, it's a fresh fetch, so it's a new loading cycle.
    if (!loadMore) {
      setLoading(); // Set BaseProvider's loading state for initial fetch
    }
    // For loadMore, we don't set the main loading state, as it's a background fetch.
    // The UI might have a separate indicator for "loading more".

    try {
      // _isLoadingMore = loadMore; // Removed
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
            // Don't set global error for partial failure, just log.
          }
        } catch (e) {
          _logger.e('NotificationProvider: Error fetching from $endpoint: $e');
          // Don't set global error for partial failure, just log.
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
      setSuccess(); // Use BaseProvider's setSuccess
      return _notifications;
    } catch (e) {
      _logger.e('NotificationProvider: Failed to fetch notifications: $e');
      setError(e.toString()); // Use BaseProvider's setError
      return [];
    } finally {
      // _isLoadingMore = false; // Removed
      // BaseProvider's state is handled by setLoading/setSuccess/setError
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    setLoading(); // Indicate loading for this specific operation
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
        setSuccess(); // Use BaseProvider's setSuccess
        return true;
      }

      setError(
        response['message'] ?? 'Failed to mark notification as read',
      ); // Use BaseProvider's setError
      _logger.w(
        'NotificationProvider: Failed to mark notification as read - Status: ${response['statusCode']}',
      );
      return false;
    } catch (e) {
      setError(e.toString()); // Use BaseProvider's setError
      _logger.e(
        'NotificationProvider: Failed to mark notification as read: $e',
      );
      return false;
    }
  }

  Future<bool> markAllAsRead(String userId) async {
    setLoading(); // Indicate loading for this specific operation
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
        setSuccess(); // Use BaseProvider's setSuccess
        return true;
      }

      setError(
        response['message'] ?? 'Failed to mark all notifications as read',
      ); // Use BaseProvider's setError
      _logger.w(
        'NotificationProvider: Failed to mark all notifications as read - Status: ${response['statusCode']}',
      );
      return false;
    } catch (e) {
      setError(e.toString()); // Use BaseProvider's setError
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
      setError(
        'PusherService not initialized, cannot subscribe to notifications.',
      ); // Report error
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

        _logger.i(
          'NotificationProvider: Successfully bound to all notification events',
        );
        setSuccess(); // Indicate success for subscription
      } else {
        _logger.e(
          'NotificationProvider: Failed to subscribe to notifications channel',
        );
        setError(
          'Failed to subscribe to notifications channel.',
        ); // Report error
      }
    } catch (e) {
      _logger.e(
        'NotificationProvider: Failed to subscribe to notifications: $e',
      );
      setError(
        'Error subscribing to notifications: ${e.toString()}',
      ); // Report error
    }
  }

  void _handleNotificationCreated(PusherEvent event, String userId) async {
    try {
      if (event.data is! String) {
        _logger.w(
          'NotificationProvider: Invalid NotificationCreated event data. Expected String, got ${event.data.runtimeType}',
        );
        setError(
          'Invalid NotificationCreated event data received.',
        ); // Report error
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
          setSuccess(); // Use setSuccess to notify listeners
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
      setError(
        'Error processing new notification event: ${e.toString()}',
      ); // Report error
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
    // Check BaseProvider's isLoading to prevent concurrent primary operations.
    // _isLoadingMore is removed.
    if (_currentUserId != null && _hasMore && !isLoading) {
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
    resetState(); // Use resetState to clear error and set to idle, which also calls notifyListeners
  }

  // Method to unsubscribe from notifications (useful for logout)
  Future<void> unsubscribeFromNotifications() async {
    if (_isSubscribedToGeneralChannel) {
      await _pusherService.unsubscribeFromChannel('notifications');
      _isSubscribedToGeneralChannel = false;
      _logger.i(
        'NotificationProvider: Unsubscribed from notifications channel',
      );
      setSuccess(); // Indicate success for unsubscription
    }
  }

  @override
  void dispose() {
    // It's generally better to await async operations in dispose if possible,
    // but if the app is shutting down, it might not complete.
    // For now, keep it as is, but be aware of potential uncompleted async ops.
    unsubscribeFromNotifications();
    _logger.i('NotificationProvider: Disposed');
    super.dispose();
  }
}
