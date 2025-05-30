import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wawu_mobile/models/notification.dart';
import 'package:wawu_mobile/services/api_service.dart';
import 'package:wawu_mobile/services/pusher_service.dart';
import 'package:wawu_mobile/providers/base_provider.dart';
import 'dart:convert';

class NotificationProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  List<NotificationModel> _notifications = [];
  bool _isSubscribedToGeneralChannel = false;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasMore => _hasMore;

  NotificationProvider({ApiService? apiService, PusherService? pusherService})
      : _apiService = apiService ?? ApiService(),
        _pusherService = pusherService ?? PusherService() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showPushNotification(NotificationModel notification) async {
    const androidDetails = AndroidNotificationDetails(
      'notification_channel',
      'Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const platformDetails = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
    await _notificationsPlugin.show(
      notification.id.hashCode,
      _getNotificationTitle(notification.type),
      notification.data['message']?.toString() ?? 'New notification',
      platformDetails,
    );
  }

  String _getNotificationTitle(String type) {
    const titles = {
      'App\\Notifications\\UserSubscribed': 'Subscription Update',
      'App\\Notifications\\UserLogin': 'Login Alert',
      'App\\Notifications\\PaymentSuccessful': 'Payment Success',
      'App\\Notifications\\PaymentDeclined': 'Payment Declined',
      'App\\Notifications\\NewMessage': 'New Message',
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
      if (!loadMore) {
        _currentPage = 1;
        _notifications = [];
      } else {
        _currentPage++;
      }

      // Fetch both read and unread notifications
      final endpoints = ['/notifications/unread', '/notifications/read'];
      List<NotificationModel> allNotifications = [];

      for (final endpoint in endpoints) {
        final response = await _apiService.get<Map<String, dynamic>>(
          endpoint,
          queryParameters: {'page': _currentPage, 'per_page': 20},
        );

        if (response['statusCode'] == 200 && response['data']['data'] is List) {
          final List<dynamic> notificationsJson = response['data']['data'] as List<dynamic>;
          final newNotifications = notificationsJson
              .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
              .toList();
          allNotifications.addAll(newNotifications);
        } else {
          debugPrint('Invalid response format from $endpoint');
        }
      }

      _hasMore = allNotifications.length >= 20; // Approximate check; adjust if API provides next_page_url
      _notifications = loadMore ? [..._notifications, ...allNotifications] : allNotifications;
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (!_isSubscribedToGeneralChannel) {
        await _subscribeToNotificationsChannel(userId);
      }

      notifyListeners();
      return _notifications;
    } catch (e) {
      debugPrint('Failed to fetch notifications: $e');
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
        _notifications = _notifications.map((notification) {
          if (notification.id == notificationId) {
            return notification.markAsRead();
          }
          return notification;
        }).toList();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
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
        _notifications = _notifications.map((notification) => notification.markAsRead()).toList();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
      return false;
    }
  }

  Future<void> _subscribeToNotificationsChannel(String userId) async {
    const channelName = 'notifications';

    try {
      final channel = await _pusherService.subscribeToChannel(channelName);
      if (channel != null) {
        _isSubscribedToGeneralChannel = true;

        _pusherService.bindToEvent(channelName, 'NotificationCreated', (data) async {
          if (data is String) {
            final jsonData = jsonDecode(data) as Map<String, dynamic>;
            final notification = NotificationModel.fromJson(jsonData);
            if (notification.notifiableId.toString() == userId) {
              _notifications.add(notification);
              _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              await _showPushNotification(notification);
              notifyListeners();
            }
          }
        });

        _pusherService.bindToEvent(channelName, 'NotificationRead', (data) async {
          if (data is String) {
            final jsonData = jsonDecode(data) as Map<String, dynamic>;
            final notificationId = jsonData['notification_id'] as String? ?? jsonData['id'] as String?;
            if (notificationId != null) {
              final index = _notifications.indexWhere((n) => n.id == notificationId);
              if (index != -1) {
                _notifications[index] = _notifications[index].markAsRead();
                notifyListeners();
              }
            }
          }
        });

        _pusherService.bindToEvent(channelName, 'AllNotificationsRead', (data) async {
          if (data is String) {
            final jsonData = jsonDecode(data) as Map<String, dynamic>;
            if (jsonData['user_id']?.toString() == userId) {
              _notifications = _notifications.map((notification) => notification.markAsRead()).toList();
              notifyListeners();
            }
          }
        });

        _pusherService.bindToEvent(channelName, 'NotificationDeleted', (data) async {
          if (data is String) {
            final jsonData = jsonDecode(data) as Map<String, dynamic>;
            final notificationId = jsonData['notification_id'] as String? ?? jsonData['id'] as String?;
            if (notificationId != null) {
              _notifications.removeWhere((notification) => notification.id == notificationId);
              notifyListeners();
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to subscribe to notifications: $e');
    }
  }

  void clearAll() {
    _notifications = [];
    _currentPage = 1;
    _hasMore = true;
    _isSubscribedToGeneralChannel = false;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isSubscribedToGeneralChannel) {
      _pusherService.unsubscribeFromChannel('notifications');
    }
    super.dispose();
  }
}