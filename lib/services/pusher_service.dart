import 'package:logger/logger.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  final Logger _logger = Logger();
  PusherChannelsFlutter? _pusher;
  final Map<String, bool> _subscribedChannels = {};
  final Map<String, Map<String, Function(PusherEvent)>> _eventBindings = {};
  final Map<String, Map<String, Function(PusherEvent)>>
  _persistentEventBindings = {};
  bool _isInitialized = false;
  String? _currentUserId;
  final StreamController<bool> _initStreamController =
      StreamController<bool>.broadcast();
  Timer? _reconnectTimer;
  bool _isReconnecting = false;

  // Pusher internal events that don't need custom handlers
  static const Set<String> _internalPusherEvents = {
    'pusher:subscription_succeeded',
    'pusher:subscription_error',
    'pusher:connection_established',
    'pusher:error',
    'pusher:ping',
    'pusher:pong',
    'pusher_internal:subscription_succeeded',
    'pusher_internal:subscription_error',
    'pusher_internal:member_added',
    'pusher_internal:member_removed',
  };

  bool get isInitialized => _isInitialized;
  Stream<bool> get onInitialized => _initStreamController.stream;

  // Parse event data to ensure it's a Map<String, dynamic>, handling nested JSON strings
  Map<String, dynamic> _parseEventData(dynamic eventData) {
    try {
      if (eventData is String) {
        return jsonDecode(eventData) as Map<String, dynamic>;
      } else if (eventData is Map<String, dynamic>) {
        // Handle nested JSON strings within the map
        return eventData.map((key, value) {
          if (value is String) {
            try {
              // Attempt to decode nested JSON strings (e.g., eventData['user'])
              return MapEntry(key, jsonDecode(value));
            } catch (_) {
              // If not a valid JSON string, keep the original value
              return MapEntry(key, value);
            }
          } else if (value is Map) {
            // Recursively parse nested maps
            return MapEntry(key, _parseEventData(value));
          } else if (value is List) {
            // Handle lists, parsing any nested maps
            return MapEntry(
              key,
              value
                  .map((item) => item is Map ? _parseEventData(item) : item)
                  .toList(),
            );
          }
          return MapEntry(key, value);
        });
      } else if (eventData is Map) {
        // Handle LinkedMap<Object?, Object?> by converting to Map<String, dynamic>
        return Map<String, dynamic>.from(
          eventData.map((key, value) {
            if (value is Map) {
              return MapEntry(key.toString(), _parseEventData(value));
            } else if (value is List) {
              return MapEntry(
                key.toString(),
                value
                    .map((item) => item is Map ? _parseEventData(item) : item)
                    .toList(),
              );
            } else if (value is String) {
              try {
                return MapEntry(key.toString(), jsonDecode(value));
              } catch (_) {
                return MapEntry(key.toString(), value);
              }
            }
            return MapEntry(key.toString(), value);
          }),
        );
      }
      throw Exception('Unexpected event data type: ${eventData.runtimeType}');
    } catch (e) {
      _logger.e('PusherService: Error parsing event data: $e');
      rethrow;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.d('PusherService: Already initialized. Skipping initialization.');
      _initStreamController.add(true);
      return;
    }

    _logger.i('PusherService: Attempting to initialize...');

    try {
      await dotenv.load();
      final appKey = dotenv.env['PUSHER_APP_KEY'];
      final cluster = dotenv.env['PUSHER_CLUSTER'] ?? 'eu';
      final authEndpoint =
          dotenv.env['PUSHER_AUTH_ENDPOINT'] ??
          'https://your-backend.com/pusher/auth';

      if (appKey == null || appKey.isEmpty) {
        throw Exception(
          'PusherService: PUSHER_APP_KEY is not set in .env file',
        );
      }

      if (kIsWeb) {
        _logger.d('PusherService: Running on Web platform');
        await Future.delayed(const Duration(milliseconds: 1000));
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
        onAuthorizer: (
          String channelName,
          String socketId,
          dynamic options,
        ) async {
          _logger.d(
            'PusherService: Authorizing channel $channelName with socketId $socketId',
          );
          try {
            final response = await http.post(
              Uri.parse(authEndpoint),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'socket_id': socketId,
                'channel_name': channelName,
              }),
            );
            if (response.statusCode == 200) {
              return jsonDecode(response.body);
            } else {
              _logger.e(
                'PusherService: Authorization failed for $channelName: ${response.body}',
              );
              throw Exception('Authorization failed: ${response.statusCode}');
            }
          } catch (e) {
            _logger.e(
              'PusherService: Authorization error for $channelName: $e',
            );
            rethrow;
          }
        },
      );

      _logger.d(
        'PusherService: Pusher init completed, attempting to connect...',
      );

      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          await _pusher!.connect();
          _logger.i('PusherService: Connection successful');
          break;
        } catch (e) {
          _logger.e('PusherService: Connection attempt $attempt failed: $e');
          if (attempt == 3) {
            throw Exception('Failed to connect to Pusher after 3 attempts');
          }
          await Future.delayed(Duration(milliseconds: 1000 * attempt));
        }
      }

      _isInitialized = true;
      _initStreamController.add(true);
      _logger.i('PusherService: Initialization successful and connected');

      _logger.d('PusherService: Subscribing to general channels...');
      await Future.wait([
        subscribeToChannel('ads'),
        subscribeToChannel('posts'),
        subscribeToChannel('gigs'),
        subscribeToChannel('products'),
        subscribeToChannel('notifications'),
      ]);

      if (_currentUserId != null) {
        await _subscribeToUserChannel(_currentUserId!);
      }
    } catch (e, stackTrace) {
      _logger.e(
        'PusherService: FATAL ERROR during initialization: $e\nStack trace: $stackTrace',
      );
      if (kIsWeb) {
        _logger.e(
          'PusherService: Web platform error - ensure Pusher JS library is included in index.html',
        );
      }
      _isInitialized = false;
      _initStreamController.add(false);
      rethrow;
    }
  }

  void _onConnectionStateChange(dynamic currentState, dynamic previousState) {
    _logger.i(
      'PusherService: Connection state changed from $previousState to $currentState',
    );

    if (currentState == 'CONNECTED') {
      _isInitialized = true;
      _initStreamController.add(true);
      _isReconnecting = false;
      _reconnectTimer?.cancel();
      _logger.i('PusherService: Connected. Resubscribing to channels...');
      // Add delay to ensure connection is stable before resubscribing
      Future.delayed(const Duration(milliseconds: 500), () {
        resubscribeToChannels();
      });
    } else if (currentState == 'DISCONNECTED') {
      _isInitialized = false;
      _initStreamController.add(false);
      _logger.w('PusherService: Disconnected. Channels inactive.');
      _scheduleReconnect();
    } else if (currentState == 'CONNECTING') {
      _logger.d('PusherService: Connecting...');
    } else if (currentState == 'RECONNECTING') {
      _logger.i('PusherService: Reconnecting...');
      _isReconnecting = true;
    }
  }

  void _scheduleReconnect() {
    if (_isReconnecting) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      if (!_isInitialized && _pusher != null) {
        _logger.i('PusherService: Attempting automatic reconnection...');
        try {
          await _pusher!.connect();
        } catch (e) {
          _logger.e('PusherService: Automatic reconnection failed: $e');
          _scheduleReconnect(); // Schedule another attempt
        }
      }
    });
  }

  void _onError(String message, int? code, dynamic e) {
    _logger.e(
      'PusherService: Error - Message: $message, Code: $code, Exception: $e',
    );
  }

  void _onGlobalEvent(PusherEvent event) {
    // Skip logging and handler lookup for internal Pusher events
    if (_internalPusherEvents.contains(event.eventName)) {
      _logger.d(
        'PusherService: Received internal event "${event.eventName}" on channel "${event.channelName}"',
      );
      return;
    }

    _logger.i(
      'PusherService: Received event "${event.eventName}" on channel "${event.channelName}". Raw data: ${event.data}',
    );

    // Check both current and persistent event bindings
    Map<String, Function(PusherEvent)>? channelBindings =
        _eventBindings[event.channelName] ??
        _persistentEventBindings[event.channelName];

    if (channelBindings != null &&
        channelBindings.containsKey(event.eventName)) {
      try {
        // Parse the event data before dispatching
        final parsedData = _parseEventData(event.data);
        // Create a new PusherEvent with parsed data
        final modifiedEvent = PusherEvent(
          channelName: event.channelName,
          eventName: event.eventName,
          data: parsedData,
        );
        _logger.d(
          'PusherService: Dispatching to handler for ${event.eventName}',
        );
        channelBindings[event.eventName]!(modifiedEvent);
      } catch (e) {
        _logger.e(
          'PusherService: Error parsing event data for ${event.eventName} on ${event.channelName}: $e',
        );
      }
    } else {
      _logger.w(
        'PusherService: No handler found for ${event.eventName} on ${event.channelName}',
      );
    }
  }

  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    _logger.i(
      'PusherService: Successfully subscribed to channel: $channelName',
    );
    _subscribedChannels[channelName] = true;
  }

  void _onSubscriptionError(String message, dynamic e) {
    _logger.e(
      'PusherService: Subscription error - Message: $message, Exception: $e',
    );
  }

  Future<void> _subscribeToUserChannel(String userId) async {
    final userChannelName = 'user.profile.$userId';
    await subscribeToChannel(userChannelName);
    _bindUserProfileEvents(userChannelName);
    _logger.d('PusherService: Subscribed to user channel: $userChannelName');
  }

  void _bindUserProfileEvents(String userChannelName) {
    _logger.d(
      'PusherService: Binding user.profile.updated event for channel: $userChannelName',
    );
    bindToEvent(userChannelName, 'user.profile.updated', (event) {
      try {
        final eventData = _parseEventData(event.data);
        _logger.i(
          'PusherService: Received user.profile.updated event: $eventData',
        );
      } catch (e, stackTrace) {
        _logger.e(
          'PusherService: Error processing user.profile.updated event: $e\nStack trace: $stackTrace',
        );
      }
    });
  }

  Future<void> subscribeToUserChannels(String userId) async {
    if (!_isInitialized || _pusher == null) {
      _logger.w(
        'PusherService: Not initialized. Cannot subscribe to user channels for user: $userId.',
      );
      return;
    }
    _currentUserId = userId;
    _logger.i(
      'PusherService: Subscribing to user-specific channels for user ID: $userId',
    );
    await _subscribeToUserChannel(userId);
  }

  Future<void> unsubscribeFromUserChannels() async {
    if (!_isInitialized || _pusher == null || _currentUserId == null) {
      _logger.w(
        'PusherService: Not initialized or no user channel subscribed. Cannot unsubscribe.',
      );
      return;
    }
    final userChannelName = 'user.profile.$_currentUserId';
    await unsubscribeFromChannel(userChannelName);
    _currentUserId = null;
    _logger.d(
      'PusherService: Unsubscribed from user channels and cleared user ID.',
    );
  }

  Future<bool> subscribeToChannel(String channelName) async {
    if (!_isInitialized || _pusher == null) {
      _logger.e(
        'PusherService: Not initialized. Cannot subscribe to channel: $channelName',
      );
      return false;
    }

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        if (_subscribedChannels.containsKey(channelName) &&
            _subscribedChannels[channelName] == true) {
          _logger.d(
            'PusherService: Already subscribed to channel: $channelName.',
          );
          return true;
        }

        await _pusher!.subscribe(channelName: channelName);
        _logger.i(
          'PusherService: Subscription request sent for channel: $channelName',
        );

        // Wait a bit for subscription to be confirmed
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      } catch (e) {
        _logger.e(
          'PusherService: Attempt $attempt failed for channel $channelName: $e',
        );
        if (attempt == 3) {
          _subscribedChannels[channelName] = false;
          return false;
        }
        await Future.delayed(Duration(milliseconds: 1000 * attempt));
      }
    }
    return false;
  }

  void bindToEvent(
    String channelName,
    String eventName,
    void Function(PusherEvent) onEvent,
  ) {
    if (!_eventBindings.containsKey(channelName)) {
      _eventBindings[channelName] = {};
    }
    if (!_persistentEventBindings.containsKey(channelName)) {
      _persistentEventBindings[channelName] = {};
    }

    _eventBindings[channelName]![eventName] = onEvent;
    _persistentEventBindings[channelName]![eventName] = onEvent;

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
        _eventBindings.remove(channelName);
        _persistentEventBindings.remove(channelName);
        _logger.i('PusherService: Unsubscribed from channel: $channelName');
      } catch (e) {
        _logger.e(
          'PusherService: Error unsubscribing from channel $channelName: $e',
        );
      }
    } else {
      _logger.d(
        'PusherService: Channel $channelName not found in active subscriptions.',
      );
    }
  }

  Future<void> disconnect() async {
    _logger.i('PusherService: Disconnecting...');
    _reconnectTimer?.cancel();
    _subscribedChannels.clear();
    _eventBindings.clear();
    _persistentEventBindings.clear();
    if (_pusher != null) {
      await _pusher!.disconnect();
    }
    _isInitialized = false;
    _currentUserId = null;
    _initStreamController.add(false);
    _logger.d('PusherService: Disconnected and state reset.');
  }

  Future<void> resubscribeToChannels() async {
    if (!_isInitialized || _pusher == null) {
      _logger.w('PusherService: Not initialized. Cannot resubscribe.');
      return;
    }

    _logger.i('PusherService: Resubscribing to channels...');

    // Get channels that were previously subscribed
    final channelsToResubscribe =
        _subscribedChannels.keys
            .where((channel) => _subscribedChannels[channel] == true)
            .toList();

    // Clear current subscription status but keep persistent bindings
    _subscribedChannels.clear();
    _eventBindings.clear();

    // Resubscribe to all channels
    for (final channelName in channelsToResubscribe) {
      _logger.d('PusherService: Resubscribing to channel: $channelName');
      await subscribeToChannel(channelName);

      // Restore event bindings from persistent storage
      if (_persistentEventBindings.containsKey(channelName)) {
        _eventBindings[channelName] = Map.from(
          _persistentEventBindings[channelName]!,
        );
        _logger.d(
          'PusherService: Restored ${_eventBindings[channelName]!.length} event bindings for $channelName',
        );
      }
    }

    // Resubscribe to user channel if needed
    if (_currentUserId != null) {
      await _subscribeToUserChannel(_currentUserId!);
    }

    _logger.i(
      'PusherService: Resubscription completed for ${channelsToResubscribe.length} channels.',
    );
  }

  Future<Channel?> subscribeToChannelCompat(String channelName) async {
    final success = await subscribeToChannel(channelName);
    return success ? Channel(channelName) : null;
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _initStreamController.close();
  }
}

class Channel {
  final String name;
  Channel(this.name);
  void bind(String eventName, Function(dynamic) callback) {
    // Deprecated, handled by PusherService.bindToEvent
  }
}
