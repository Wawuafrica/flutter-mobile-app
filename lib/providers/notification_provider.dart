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
import 'package:wawu_mobile/utils/constants/colors.dart';

// TOP-LEVEL FUNCTION - This is required for background notifications
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Handle background notification tap
  final logger = Logger();
  logger.i('Background notification tapped: ${response.payload}');

  // You can add navigation logic here if needed
  // For example, you might want to store the notification data
  // in shared preferences to handle when the app becomes active
}

class NotificationProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();

  List<NotificationModel> _notifications = [];
  bool _isSubscribedToUserChannel = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _currentUserId; // Store current user ID for filtering
  String? _currentChannelName; // Store current channel name

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
      // Request permissions first
      bool permissionGranted = false;

      if (Platform.isAndroid) {
        final androidPlugin =
            _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        // Create notification channel first
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            'notification_channel',
            'Notifications',
            description: 'Channel for app notifications',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
        );

        // Request permission
        final granted = await androidPlugin?.requestNotificationsPermission();
        permissionGranted = granted ?? false;

        if (!permissionGranted) {
          _logger.w(
            'NotificationProvider: Android notification permission not granted',
          );
          return;
        }
      } else if (Platform.isIOS) {
        final iosPlugin =
            _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >();

        final granted = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        permissionGranted = granted ?? false;

        if (!permissionGranted) {
          _logger.w(
            'NotificationProvider: iOS notification permission not granted',
          );
          return;
        }
      }

      // Initialize notifications
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false, // Already requested above
          requestBadgePermission: false, // Already requested above
          requestSoundPermission: false, // Already requested above
        ),
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
        onDidReceiveBackgroundNotificationResponse:
            notificationTapBackground, // Use top-level function
      );

      _logger.i(
        'NotificationProvider: Local notifications initialized successfully',
      );
    } catch (e) {
      _logger.e(
        'NotificationProvider: Failed to initialize local notifications: $e',
      );
    }
  }

  // Instance method for handling foreground notification taps
  void _handleNotificationTap(NotificationResponse response) {
    _logger.i('Notification tapped: ${response.payload}');

    // Handle notification tap (e.g., navigate to a specific screen)
    // You can parse the payload and navigate accordingly
    try {
      if (response.payload != null) {
        final payload = jsonDecode(response.payload!);
        // Handle navigation based on payload
        _logger.d('Notification payload: $payload');
      }
    } catch (e) {
      _logger.e('Error parsing notification payload: $e');
    }
  }

  Future<void> _showPushNotification(NotificationModel notification) async {
    try {
      // Create payload with notification data
      final payload = jsonEncode({
        'id': notification.id,
        'type': notification.type,
        'data': notification.data,
      });

      const androidDetails = AndroidNotificationDetails(
        'notification_channel',
        'Notifications',
        channelDescription: 'Channel for app notifications',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        color: wawuColors.primary,
        colorized: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        notification.id.hashCode,
        _getNotificationTitle(notification.type),
        notification.data['message']?.toString() ?? 'New notification',
        platformDetails,
        payload: payload,
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
    if (isLoading && loadMore) return _notifications;

    setLoading();
    if (!loadMore) {
      setLoading();
    }

    try {
      _currentUserId = userId;

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

      // Subscribe to user-specific notifications channel if not already subscribed
      if (!_isSubscribedToUserChannel) {
        await _subscribeToNotificationsChannel(userId);
      }

      _logger.i(
        'NotificationProvider: Total notifications loaded: ${_notifications.length}',
      );
      setSuccess();
      return _notifications;
    } catch (e) {
      _logger.e('NotificationProvider: Failed to fetch notifications: $e');
      setError(e.toString());
      return [];
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    setLoading();
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
        setSuccess();
        return true;
      }

      setError(response['message'] ?? 'Failed to mark notification as read');
      _logger.w(
        'NotificationProvider: Failed to mark notification as read - Status: ${response['statusCode']}',
      );
      return false;
    } catch (e) {
      setError(e.toString());
      _logger.e(
        'NotificationProvider: Failed to mark notification as read: $e',
      );
      return false;
    }
  }

  Future<bool> markAllAsRead(String userId) async {
    setLoading();
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
        setSuccess();
        return true;
      }

      setError(
        response['message'] ?? 'Failed to mark all notifications as read',
      );
      _logger.w(
        'NotificationProvider: Failed to mark all notifications as read - Status: ${response['statusCode']}',
      );
      return false;
    } catch (e) {
      setError(e.toString());
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
      );
      return;
    }

    // Create user-specific channel name
    final channelName = 'NotificationsCreated.$userId';
    _currentChannelName = channelName;

    try {
      final success = await _pusherService.subscribeToChannel(channelName);
      if (success) {
        _isSubscribedToUserChannel = true;
        _logger.i(
          'NotificationProvider: Successfully subscribed to user-specific notifications channel: $channelName',
        );

        // Bind to NotificationCreated event on the user-specific channel
        _pusherService.bindToEvent(channelName, 'NotificationCreated', (
          PusherEvent event,
        ) {
          _handleNotificationCreated(event);
        });

        _logger.i(
          'NotificationProvider: Successfully bound to NotificationCreated event on channel: $channelName',
        );
        setSuccess();
      } else {
        _logger.e(
          'NotificationProvider: Failed to subscribe to user-specific notifications channel: $channelName',
        );
        setError('Failed to subscribe to notifications channel.');
      }
    } catch (e) {
      _logger.e(
        'NotificationProvider: Failed to subscribe to notifications: $e',
      );
      setError('Error subscribing to notifications: ${e.toString()}');
    }
  }

  void _handleNotificationCreated(PusherEvent event) async {
    try {
      if (event.data is! String) {
        _logger.w(
          'NotificationProvider: Invalid NotificationCreated event data. Expected String, got ${event.data.runtimeType}',
        );
        setError('Invalid NotificationCreated event data received.');
        return;
      }

      final jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      final notification = NotificationModel.fromJson(jsonData);

      _logger.i(
        'NotificationProvider: Received NotificationCreated event for notification ${notification.id}',
      );

      // Check if notification already exists to avoid duplicates
      final existingIndex = _notifications.indexWhere(
        (n) => n.id == notification.id,
      );
      if (existingIndex == -1) {
        _notifications.add(notification);
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        await _showPushNotification(notification);
        setSuccess();
        _logger.i(
          'NotificationProvider: Added new notification ${notification.id}',
        );
      } else {
        _logger.d(
          'NotificationProvider: Notification ${notification.id} already exists, skipping',
        );
      }
    } catch (e) {
      _logger.e(
        'NotificationProvider: Error processing NotificationCreated event: $e',
      );
      setError('Error processing new notification event: ${e.toString()}');
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
    if (_currentUserId != null && _hasMore && !isLoading) {
      await fetchNotifications(_currentUserId!, loadMore: true);
    }
  }

  // Method to clear notification badge (call this when user opens notifications screen)
  Future<void> clearNotificationBadge() async {
    try {
      await _notificationsPlugin.cancelAll();
      if (Platform.isIOS) {
        final iosPlugin =
            _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >();
        await iosPlugin?.requestPermissions(badge: false);
      }
    } catch (e) {
      _logger.e('Error clearing notification badge: $e');
    }
  }

  void clearAll() {
    _notifications = [];
    _currentPage = 1;
    _hasMore = true;
    _isSubscribedToUserChannel = false;
    _currentUserId = null;
    _currentChannelName = null;
    _logger.i('NotificationProvider: Cleared all notifications data');
    resetState();
  }

  // Method to unsubscribe from notifications (useful for logout)
  Future<void> unsubscribeFromNotifications() async {
    if (_isSubscribedToUserChannel && _currentChannelName != null) {
      await _pusherService.unsubscribeFromChannel(_currentChannelName!);
      _isSubscribedToUserChannel = false;
      _currentChannelName = null;
      _logger.i(
        'NotificationProvider: Unsubscribed from user-specific notifications channel',
      );
      setSuccess();
    }
  }

  @override
  void dispose() {
    unawaited(unsubscribeFromNotifications());
    _logger.i('NotificationProvider: Disposed');
    super.dispose();
  }
}
