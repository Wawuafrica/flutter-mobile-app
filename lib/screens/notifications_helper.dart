import 'dart:io';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wawu_mobile/models/notification.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'dart:math';
import 'package:wawu_mobile/utils/constants/colors.dart';


class TestNotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final Logger _logger = Logger();

  // Sample notification data for testing
  static final List<Map<String, dynamic>> _sampleNotifications = [
    {
      'id': 'test_1',
      'type': 'App\\Notifications\\NewMessage',
      'data': {
        'message': 'You have a new message from John Doe',
        'sender': 'John Doe',
        'messageId': '12345',
      },
      'notifiable_id': 1,
      'read_at': null,
      'created_at':
          DateTime.now().subtract(Duration(minutes: 5)).toIso8601String(),
    },
    {
      'id': 'test_2',
      'type': 'App\\Notifications\\NewLike',
      'data': {
        'message': 'Sarah liked your post',
        'userId': '67890',
        'postId': '54321',
      },
      'notifiable_id': 1,
      'read_at': null,
      'created_at':
          DateTime.now().subtract(Duration(minutes: 10)).toIso8601String(),
    },
    {
      'id': 'test_3',
      'type': 'App\\Notifications\\PaymentSuccessful',
      'data': {
        'message': 'Payment of \$29.99 processed successfully',
        'amount': '29.99',
        'transactionId': 'TXN_987654321',
      },
      'notifiable_id': 1,
      'read_at': null,
      'created_at':
          DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
    },
    {
      'id': 'test_4',
      'type': 'App\\Notifications\\NewFollow',
      'data': {
        'message': 'Mike started following you',
        'followerId': '11111',
        'followerName': 'Mike Johnson',
      },
      'notifiable_id': 1,
      'read_at': null,
      'created_at':
          DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
    },
    {
      'id': 'test_5',
      'type': 'App\\Notifications\\PostApproved',
      'data': {
        'message': 'Your post "Flutter Development Tips" has been approved',
        'postId': '98765',
        'postTitle': 'Flutter Development Tips',
      },
      'notifiable_id': 1,
      'read_at': null,
      'created_at':
          DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
    },
  ];

  /// Initialize test notifications (call this once in your app)
  static Future<void> initialize() async {
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
      onDidReceiveNotificationResponse: (response) {
        _logger.i('Test notification tapped: ${response.payload}');
      },
    );
  }

  /// Show a single test notification immediately
  static Future<void> showTestNotification({
    String? title,
    String? body,
    String? payload,
  }) async {
    final random = Random();
    final notificationId = random.nextInt(10000);

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel for test notifications',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
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
      notificationId,
      title ?? 'Test Notification',
      body ?? 'This is a test notification from your app!',
      platformDetails,
      payload: payload ?? jsonEncode({'test': true, 'id': notificationId}),
    );

    _logger.i('Test notification shown with ID: $notificationId');
  }

  static Future<void> showScheduledTestNotification({
    required Duration delay,
    String? title,
    String? body,
  }) async {
    final scheduledDate = DateTime.now().add(delay);
    // Convert DateTime to TZDateTime - this is the key fix
    final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );
    final random = Random();
    final notificationId = random.nextInt(10000);

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel for test notifications',
      importance: Importance.high,
      priority: Priority.high,
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

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      title ?? 'Scheduled Test Notification',
      body ??
          'This scheduled notification was sent ${delay.inSeconds} seconds ago!',
      scheduledTZDate, // Use TZDateTime instead of DateTime
      platformDetails,
      payload: jsonEncode({'scheduled': true, 'id': notificationId}),
      androidScheduleMode:
          AndroidScheduleMode
              .exactAllowWhileIdle, // Add this required parameter
      // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    _logger.i('Scheduled test notification for: $scheduledTZDate');
  }

  /// Get sample notification models for testing your UI
  static List<NotificationModel> getSampleNotifications() {
    return _sampleNotifications
        .map((json) => NotificationModel.fromJson(json))
        .toList();
  }

  /// Simulate receiving a random notification (adds to your provider)
  static NotificationModel getRandomTestNotification() {
    final random = Random();
    final sampleData =
        _sampleNotifications[random.nextInt(_sampleNotifications.length)];

    // Create a unique ID for this instance
    final uniqueData = Map<String, dynamic>.from(sampleData);
    uniqueData['id'] = 'test_${DateTime.now().millisecondsSinceEpoch}';
    uniqueData['created_at'] = DateTime.now().toIso8601String();

    return NotificationModel.fromJson(uniqueData);
  }

  /// Show notifications with different types for comprehensive testing
  static Future<void> showAllTestNotificationTypes() async {
    final titles = {
      'App\\Notifications\\NewMessage': 'New Message',
      'App\\Notifications\\NewLike': 'New Like',
      'App\\Notifications\\PaymentSuccessful': 'Payment Success',
      'App\\Notifications\\NewFollow': 'New Follower',
      'App\\Notifications\\PostApproved': 'Post Approved',
    };

    for (int i = 0; i < _sampleNotifications.length; i++) {
      final notification = _sampleNotifications[i];
      final delay = Duration(seconds: i * 2); // 2 seconds apart

      Future.delayed(delay, () async {
        await showTestNotification(
          title: titles[notification['type']] ?? 'Test Notification',
          body: notification['data']['message'],
          payload: jsonEncode(notification),
        );
      });
    }
  }

  /// Cancel all test notifications
  static Future<void> cancelAllTestNotifications() async {
    await _notificationsPlugin.cancelAll();
    _logger.i('All test notifications cancelled');
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }

    // For iOS, assume enabled if we've requested permissions
    return true;
  }
}
