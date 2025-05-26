import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:pusher_client_fixed/pusher_client_fixed.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert'; // Import for jsonDecode

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  final Logger _logger = Logger();
  PusherClient? _pusher;
  final Map<String, Channel> _channels = {};
  bool _isInitialized = false;
  String? _currentUserId; // Store the current user ID for user-specific channels

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.d('PusherService: Already initialized. Skipping initialization.');
      return;
    }

    _logger.i('PusherService: Attempting to initialize...');

    try {
      final appKey = dotenv.env['PUSHER_APP_KEY'];
      final cluster = dotenv.env['PUSHER_CLUSTER'] ?? 'eu';

      if (appKey == null || appKey.isEmpty) {
        throw Exception('PusherService: PUSHER_APP_KEY is not set in .env file');
      }

      _pusher = PusherClient(
        appKey,
        PusherOptions(
          cluster: cluster,
          encrypted: true,
          // Add timeout options if necessary for debugging connection issues
          // activityTimeout: 60000, // 60 seconds
          // pongTimeout: 30000, // 30 seconds
        ),
        autoConnect: true, // Let Pusher manage auto-connection
        enableLogging: kDebugMode,
      );

      _pusher?.onConnectionStateChange((state) {
        _logger.i('PusherService: Connection state changed: ${state?.currentState}');
        if (state?.currentState == 'CONNECTED') {
          _logger.i('PusherService: Connected. Attempting to resubscribe to all channels.');
          resubscribeToChannels(); // Re-subscribe to all channels on successful connection
        } else if (state?.currentState == 'DISCONNECTED') {
          _logger.w('PusherService: Disconnected. Channels might be inactive.');
        } else if (state?.currentState == 'CONNECTING') {
          _logger.d('PusherService: Connecting...');
        }
      });

      _pusher?.onConnectionError((error) {
        _logger.e('PusherService: Connection error: ${error?.message}, Code: ${error?.code}, Data: ${error?.message}');
      });

      // Explicitly connect if autoConnect didn't trigger immediately
      _pusher?.connect();

      // Set initialized flag only after attempting connection
      _isInitialized = true;
      _logger.d('PusherService: Initialization successful and connection attempted.');

      // Subscribe to general channels immediately after initialization logic
      // These are not dependent on connection state for *subscription* but for *receiving* events.
      // resubscribeToChannels will handle actual subscription logic on connection.
      _logger.d('PusherService: Preparing to subscribe to general channels.');
      await subscribeToChannel('ads');
      await subscribeToChannel('posts');
      await subscribeToChannel('gigs');
      await subscribeToChannel('products');
      await subscribeToChannel('notifications');

    } catch (e) {
      _logger.e('PusherService: FATAL ERROR during initialization: $e');
      _isInitialized = false; // Ensure flag is reset on failure
      rethrow; // Re-throw to be caught in main.dart
    }
  }

  // Private helper method for re-subscribing to the user channel
  Future<void> _subscribeToUserChannel(String userId) async {
    final userChannelName = 'user.profile.$userId';
    await subscribeToChannel(userChannelName);
    // Re-bind user-specific events here if necessary
    _bindUserProfileEvents(userChannelName);
    _logger.d('PusherService: Subscribed to user channel: $userChannelName');
  }

  // Method to subscribe to user-specific channels after authentication
  Future<void> subscribeToUserChannels(String userId) async {
    if (!_isInitialized || _pusher == null) {
      _logger.w('PusherService: Not initialized. Cannot subscribe to user channels for user: $userId.');
      return;
    }
    // Store the current user ID
    _currentUserId = userId;
    _logger.i('PusherService: Attempting to subscribe to user-specific channels for user ID: $userId');
    await _subscribeToUserChannel(userId);
  }

  // Helper method to bind user profile events
  void _bindUserProfileEvents(String userChannelName) {
    _logger.d('PusherService: Binding user.profile.updated event for channel: $userChannelName');
    bindToEvent(userChannelName, 'user.profile.updated', (data) {
      try {
        if (data is! String) {
          _logger.w('PusherService: Invalid user.profile.updated event data. Expected String, got ${data.runtimeType}');
          return;
        }
        final eventData = jsonDecode(data) as Map<String, dynamic>;
        // Handle user profile update event
        _logger.i('PusherService: Received user.profile.updated event: $eventData');
        // You would typically update the UserProvider state here
        // Access UserProvider via a callback or event bus if needed
      } catch (e) {
        _logger.e('PusherService: Error processing user.profile.updated event: $e. Data: $data');
      }
    });
  }

  // Method to unsubscribe from user-specific channels on logout
  Future<void> unsubscribeFromUserChannels() async {
    if (!_isInitialized || _pusher == null || _currentUserId == null) {
      _logger.w('PusherService: Not initialized or no user channel subscribed. Cannot unsubscribe from user channels.');
      return;
    }

    final userChannelName = 'user.profile.$_currentUserId';
    await unsubscribeFromChannel(userChannelName);

    // Clear the stored user ID
    _currentUserId = null;
    _logger.d('PusherService: Unsubscribed from user channels and cleared current user ID.');
  }

  Future<Channel?> subscribeToChannel(String channelName) async {
    if (!_isInitialized || _pusher == null) {
      _logger.e('PusherService: Not initialized. Cannot subscribe to channel: $channelName');
      return null;
    }

    try {
      if (_channels.containsKey(channelName)) {
        _logger.d('PusherService: Already subscribed to channel: $channelName. Returning existing channel.');
        return _channels[channelName];
      }

      final channel = _pusher!.subscribe(channelName);
      _channels[channelName] = channel;
      _logger.i('PusherService: Subscribed to channel: $channelName');
      return channel;
    } catch (e) {
      _logger.e('PusherService: Error subscribing to channel $channelName: $e');
      return null;
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
        'PusherService: Attempted to bind to event $eventName on non-existent channel: $channelName',
      );
      return;
    }

    channel.bind(eventName, (event) {
      _logger.i(
        'PusherService: Received event "$eventName" on channel "$channelName". Raw data: ${event?.data}',
      );
      onEvent(event?.data);
    });
  }

  Future<void> unsubscribeFromChannel(String channelName) async {
    final channel = _channels.remove(channelName);
    if (channel != null) {
      _pusher?.unsubscribe(channelName);
      _logger.i('PusherService: Unsubscribed from channel: $channelName');
    } else {
      _logger.d('PusherService: Channel $channelName not found in active subscriptions. No action needed.');
    }
  }

  void disconnect() {
    _logger.i('PusherService: Disconnecting...');
    _channels.clear(); // Clear all subscribed channels
    _pusher?.disconnect();
    _isInitialized = false;
    _currentUserId = null; // Clear user ID on disconnection
    _logger.d('PusherService: Disconnected and state reset.');
  }

  // Method to re-subscribe to all channels (general and user-specific) after reconnection
  Future<void> resubscribeToChannels() async {
    if (!_isInitialized || _pusher == null) {
      _logger.w('PusherService: Not initialized or Pusher client is null. Cannot resubscribe.');
      return;
    }
    _logger.i('PusherService: Attempting to resubscribe to channels (general and user-specific)...');

    // Subscribe to general channels - these calls are idempotent (subscribeToChannel checks if already subscribed)
    await subscribeToChannel('ads');
    await subscribeToChannel('posts');
    await subscribeToChannel('gigs');
    await subscribeToChannel('products');
    await subscribeToChannel('notifications');

    // Subscribe to user-specific channel if user is logged in
    if (_currentUserId != null) {
      await _subscribeToUserChannel(_currentUserId!);
    }
    _logger.i('PusherService: Resubscription routine completed.');
  }
}