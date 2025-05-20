import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:pusher_client/pusher_client.dart';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  final Logger _logger = Logger();
  PusherClient? _pusher;
  final Map<String, Channel> _channels = {};
  bool _isInitialized = false;

  Future<void> initialize({
    required String userId,
  }) async {
    if (_isInitialized) return;

    try {
      // Initialize Pusher with application credentials
      _pusher = PusherClient(
        const String.fromEnvironment(
          'PUSHER_APP_KEY',
          defaultValue: 'app-key',
        ),
        PusherOptions(
          cluster: const String.fromEnvironment(
            'PUSHER_CLUSTER',
            defaultValue: 'eu',
          ),
          encrypted: true,
        ),
        autoConnect: true,
        enableLogging: kDebugMode,
      );

      _pusher?.onConnectionStateChange((state) {
        _logger.i('Pusher connection state: ${state?.currentState}');
      });

      _pusher?.onConnectionError((error) {
        _logger.e('Pusher connection error: ${error?.message}');
      });

      _isInitialized = true;

      // Subscribe to user's personal channel
      await subscribeToChannel('private-user-$userId');
      
      // Subscribe to notification channel
      await subscribeToChannel('notifications');
      
      // Subscribe to other general channels
      await subscribeToChannel('messages');
      await subscribeToChannel('products');
      await subscribeToChannel('gigs');
      await subscribeToChannel('blog');
    } catch (e) {
      _logger.e('Error initializing Pusher: $e');
      rethrow;
    }
  }

  Future<Channel?> subscribeToChannel(String channelName) async {
    if (!_isInitialized) {
      throw Exception('PusherService not initialized');
    }

    try {
      if (_channels.containsKey(channelName)) {
        return _channels[channelName];
      }

      final channel = _pusher?.subscribe(channelName);
      if (channel != null) {
        _channels[channelName] = channel;
        _logger.i('Subscribed to channel: $channelName');
      }
      return channel;
    } catch (e) {
      _logger.e('Error subscribing to channel $channelName: $e');
      rethrow;
    }
  }

  void bindToEvent(
    String channelName,
    String eventName,
    void Function(dynamic) onEvent,
  ) {
    final channel = _channels[channelName];
    if (channel == null) {
      _logger.w(
        'Attempted to bind to event on non-existent channel: $channelName',
      );
      return;
    }

    channel.bind(eventName, (event) {
      _logger.i(
        'Received event $eventName on channel $channelName: ${event?.data}',
      );
      onEvent(event?.data);
    });
  }

  Future<void> unsubscribeFromChannel(String channelName) async {
    final channel = _channels.remove(channelName);
    if (channel != null) {
      _pusher?.unsubscribe(channelName);
      _logger.i('Unsubscribed from channel: $channelName');
    }
  }

  void disconnect() {
    _channels.clear();
    _pusher?.disconnect();
    _isInitialized = false;
  }
}
