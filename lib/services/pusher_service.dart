import 'package:logger/logger.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert'; // Import for jsonDecode
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  final Logger _logger = Logger();
  PusherChannelsFlutter? _pusher;
  final Map<String, bool> _subscribedChannels = {}; // Track subscribed channels
  final Map<String, Map<String, Function(PusherEvent)>> _eventBindings =
      {}; // Track event bindings
  bool _isInitialized = false;
  String?
  _currentUserId; // Store the current user ID for user-specific channels

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
        throw Exception(
          'PusherService: PUSHER_APP_KEY is not set in .env file',
        );
      }

      // Platform-specific debugging
      if (kIsWeb) {
        _logger.d('PusherService: Running on Web platform');
        // Add a small delay to ensure Pusher JS library is loaded
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        _logger.d('PusherService: Running on ${Platform.operatingSystem}');
      }

      _logger.d(
        'PusherService: Initializing with appKey: $appKey, cluster: $cluster',
      );

      _pusher = PusherChannelsFlutter.getInstance();

      await _pusher!.init(
        apiKey: appKey,
        cluster: cluster,
        useTLS: true,
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onEvent: _onGlobalEvent,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onSubscriptionError: _onSubscriptionError,
      );

      _logger.d(
        'PusherService: Pusher init completed, attempting to connect...',
      );

      // Connect to Pusher
      await _pusher!.connect();

      // Set initialized flag only after attempting connection
      _isInitialized = true;
      _logger.d(
        'PusherService: Initialization successful and connection attempted.',
      );

      // Subscribe to general channels immediately after initialization logic
      _logger.d('PusherService: Preparing to subscribe to general channels.');
      await subscribeToChannel('ads');
      await subscribeToChannel('posts');
      await subscribeToChannel('gigs');
      await subscribeToChannel('products');
      await subscribeToChannel('notifications');
    } catch (e, stackTrace) {
      _logger.e('PusherService: FATAL ERROR during initialization: $e');
      _logger.e('PusherService: Stack trace: $stackTrace');

      // Additional debugging for web platform
      if (kIsWeb) {
        _logger.e(
          'PusherService: Web platform error - check if Pusher JS library is loaded in index.html',
        );
      }

      _isInitialized = false; // Ensure flag is reset on failure
      rethrow; // Re-throw to be caught in main.dart
    }
  }

  // Connection state change callback
  void _onConnectionStateChange(dynamic currentState, dynamic previousState) {
    _logger.i(
      'PusherService: Connection state changed from $previousState to $currentState',
    );
    if (currentState == 'CONNECTED') {
      _logger.i(
        'PusherService: Connected. Attempting to resubscribe to all channels.',
      );
      resubscribeToChannels(); // Re-subscribe to all channels on successful connection
    } else if (currentState == 'DISCONNECTED') {
      _logger.w('PusherService: Disconnected. Channels might be inactive.');
    } else if (currentState == 'CONNECTING') {
      _logger.d('PusherService: Connecting...');
    } else if (currentState == 'RECONNECTING') {
      _logger.i('PusherService: Reconnecting...');
    }
  }

  // Error callback
  void _onError(String message, int? code, dynamic e) {
    _logger.e(
      'PusherService: Error - Message: $message, Code: $code, Exception: $e',
    );
  }

  // Global event callback
  void _onGlobalEvent(PusherEvent event) {
    _logger.i(
      'PusherService: Received global event "${event.eventName}" on channel "${event.channelName}". Data: ${event.data}',
    );

    // Check if we have specific bindings for this channel and event
    if (_eventBindings.containsKey(event.channelName) &&
        _eventBindings[event.channelName]!.containsKey(event.eventName)) {
      _eventBindings[event.channelName]![event.eventName]!(event);
    }
  }

  // Subscription succeeded callback
  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    _logger.i(
      'PusherService: Successfully subscribed to channel: $channelName',
    );
    _subscribedChannels[channelName] = true;
  }

  // Subscription error callback
  void _onSubscriptionError(String message, dynamic e) {
    _logger.e(
      'PusherService: Subscription error - Message: $message, Exception: $e',
    );
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
      _logger.w(
        'PusherService: Not initialized. Cannot subscribe to user channels for user: $userId.',
      );
      return;
    }
    // Store the current user ID
    _currentUserId = userId;
    _logger.i(
      'PusherService: Attempting to subscribe to user-specific channels for user ID: $userId',
    );
    await _subscribeToUserChannel(userId);
  }

  // Helper method to bind user profile events
  void _bindUserProfileEvents(String userChannelName) {
    _logger.d(
      'PusherService: Binding user.profile.updated event for channel: $userChannelName',
    );
    bindToEvent(userChannelName, 'user.profile.updated', (event) {
      try {
        if (event.data is! String) {
          _logger.w(
            'PusherService: Invalid user.profile.updated event data. Expected String, got ${event.data.runtimeType}',
          );
          return;
        }
        final eventData = jsonDecode(event.data) as Map<String, dynamic>;
        // Handle user profile update event
        _logger.i(
          'PusherService: Received user.profile.updated event: $eventData',
        );
        // You would typically update the UserProvider state here
        // Access UserProvider via a callback or event bus if needed
      } catch (e) {
        _logger.e(
          'PusherService: Error processing user.profile.updated event: $e. Data: ${event.data}',
        );
      }
    });
  }

  // Method to unsubscribe from user-specific channels on logout
  Future<void> unsubscribeFromUserChannels() async {
    if (!_isInitialized || _pusher == null || _currentUserId == null) {
      _logger.w(
        'PusherService: Not initialized or no user channel subscribed. Cannot unsubscribe from user channels.',
      );
      return;
    }

    final userChannelName = 'user.profile.$_currentUserId';
    await unsubscribeFromChannel(userChannelName);

    // Clear the stored user ID
    _currentUserId = null;
    _logger.d(
      'PusherService: Unsubscribed from user channels and cleared current user ID.',
    );
  }

  Future<bool> subscribeToChannel(String channelName) async {
    if (!_isInitialized || _pusher == null) {
      _logger.e(
        'PusherService: Not initialized. Cannot subscribe to channel: $channelName',
      );
      return false;
    }

    try {
      if (_subscribedChannels.containsKey(channelName) &&
          _subscribedChannels[channelName] == true) {
        _logger.d(
          'PusherService: Already subscribed to channel: $channelName.',
        );
        return true;
      }

      await _pusher!.subscribe(channelName: channelName);
      // Note: _subscribedChannels[channelName] will be set to true in _onSubscriptionSucceeded callback
      _logger.i(
        'PusherService: Subscription request sent for channel: $channelName',
      );
      return true;
    } catch (e) {
      _logger.e('PusherService: Error subscribing to channel $channelName: $e');
      _subscribedChannels[channelName] = false;
      return false;
    }
  }

  void bindToEvent(
    String channelName,
    String eventName,
    void Function(PusherEvent) onEvent,
  ) {
    if (!_isInitialized || _pusher == null) {
      _logger.w(
        'PusherService: Not initialized. Cannot bind to event $eventName on channel: $channelName',
      );
      return;
    }

    // Store the event binding for later use
    if (!_eventBindings.containsKey(channelName)) {
      _eventBindings[channelName] = {};
    }
    _eventBindings[channelName]![eventName] = onEvent;

    _logger.i(
      'PusherService: Bound to event "$eventName" on channel "$channelName"',
    );
  }

  Future<void> unsubscribeFromChannel(String channelName) async {
    if (!_isInitialized || _pusher == null) {
      _logger.w(
        'PusherService: Not initialized. Cannot unsubscribe from channel: $channelName',
      );
      return;
    }

    if (_subscribedChannels.containsKey(channelName) &&
        _subscribedChannels[channelName] == true) {
      try {
        await _pusher!.unsubscribe(channelName: channelName);
        _subscribedChannels.remove(channelName);
        // Also remove event bindings for this channel
        _eventBindings.remove(channelName);
        _logger.i('PusherService: Unsubscribed from channel: $channelName');
      } catch (e) {
        _logger.e(
          'PusherService: Error unsubscribing from channel $channelName: $e',
        );
      }
    } else {
      _logger.d(
        'PusherService: Channel $channelName not found in active subscriptions. No action needed.',
      );
    }
  }

  Future<void> disconnect() async {
    _logger.i('PusherService: Disconnecting...');
    _subscribedChannels.clear(); // Clear all subscribed channels
    _eventBindings.clear(); // Clear all event bindings
    if (_pusher != null) {
      await _pusher!.disconnect();
    }
    _isInitialized = false;
    _currentUserId = null; // Clear user ID on disconnection
    _logger.d('PusherService: Disconnected and state reset.');
  }

  // Method to re-subscribe to all channels (general and user-specific) after reconnection
  Future<void> resubscribeToChannels() async {
    if (!_isInitialized || _pusher == null) {
      _logger.w(
        'PusherService: Not initialized or Pusher client is null. Cannot resubscribe.',
      );
      return;
    }
    _logger.i(
      'PusherService: Attempting to resubscribe to channels (general and user-specific)...',
    );

    // Store previously subscribed channels
    final channelsToResubscribe = Map<String, bool>.from(_subscribedChannels);
    final eventBindingsToRestore =
        Map<String, Map<String, Function(PusherEvent)>>.from(_eventBindings);

    // Clear current state
    _subscribedChannels.clear();
    _eventBindings.clear();

    // Re-subscribe to all previously subscribed channels
    for (final channelName in channelsToResubscribe.keys) {
      if (channelsToResubscribe[channelName] == true) {
        await subscribeToChannel(channelName);

        // Restore event bindings for this channel
        if (eventBindingsToRestore.containsKey(channelName)) {
          for (final entry in eventBindingsToRestore[channelName]!.entries) {
            bindToEvent(channelName, entry.key, entry.value);
          }
        }
      }
    }

    // Subscribe to user-specific channel if user is logged in
    if (_currentUserId != null) {
      await _subscribeToUserChannel(_currentUserId!);
    }
    _logger.i('PusherService: Resubscription routine completed.');
  }

  // Compatibility method for MessageProvider - returns a mock Channel object
  Future<Channel?> subscribeToChannelCompat(String channelName) async {
    final success = await subscribeToChannel(channelName);
    return success ? Channel(channelName) : null;
  }
}

// Mock Channel class for compatibility with existing MessageProvider code
class Channel {
  final String name;

  Channel(this.name);

  // This method is no longer used in the new implementation
  // but kept for backward compatibility
  void bind(String eventName, Function(dynamic) callback) {
    // This is handled by the global onEvent listener in PusherService
    // Individual channel binding is not supported in pusher_channels_flutter
    // Use PusherService.bindToEvent() instead
  }
}
