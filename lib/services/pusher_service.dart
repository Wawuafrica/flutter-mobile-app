import 'package:logger/logger.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:flutter/foundation.dart'; // For compute()

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: false,
    ),
    filter: ProductionFilter(), // Only log errors in production
  );
  
  PusherChannelsFlutter? _pusher;
  final Map<String, bool> _subscribedChannels = {};
  final Map<String, Map<String, Function(PusherEvent)>> _eventBindings = {};
  bool _isInitialized = false;
  String? _currentUserId;
  final StreamController<bool> _initStreamController =
      StreamController<bool>.broadcast();
  bool _isReconnecting = false;

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

  // Moved to top-level function for isolate compatibility
  static Map<String, dynamic> _parseEventDataInIsolate(dynamic eventData) {
    try {
      if (eventData is String) {
        return jsonDecode(eventData) as Map<String, dynamic>;
      } else if (eventData is Map<String, dynamic>) {
        return eventData.map((key, value) {
          if (value is String) {
            try {
              return MapEntry(key, jsonDecode(value));
            } catch (_) {
              return MapEntry(key, value);
            }
          } else if (value is Map) {
            return MapEntry(key, _parseEventDataInIsolate(value));
          } else if (value is List) {
            return MapEntry(
              key,
              value
                  .map((item) => item is Map ? _parseEventDataInIsolate(item) : item)
                  .toList(),
            );
          }
          return MapEntry(key, value);
        });
      } else if (eventData is Map) {
        return Map<String, dynamic>.from(
          eventData.map((key, value) {
            if (value is Map) {
              return MapEntry(key.toString(), _parseEventDataInIsolate(value));
            } else if (value is List) {
              return MapEntry(
                key.toString(),
                value
                    .map((item) => item is Map ? _parseEventDataInIsolate(item) : item)
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
      throw Exception('Error parsing event data: $e');
    }
  }

  Future<Map<String, dynamic>> _parseEventData(dynamic eventData) async {
    try {
      if (eventData is String && eventData.length > 1024) {
        // Offload large JSON parsing to isolate
        return await compute(_parseEventDataInIsolate, eventData);
      }
      return _parseEventDataInIsolate(eventData);
    } catch (e) {
      _logger.e('PusherService: Error parsing event data: $e');
      rethrow;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.d('PusherService: Already initialized');
      _initStreamController.add(true);
      return;
    }

    _logger.i('PusherService: Initializing...');

    try {
      // Assume env is loaded before PusherService initialization
      final appKey = dotenv.env['PUSHER_APP_KEY'];
      final cluster = dotenv.env['PUSHER_CLUSTER'];
      final authEndpoint =
          dotenv.env['PUSHER_AUTH_ENDPOINT'] ??
          'https://your-backend.com/pusher/auth';

      if (appKey == null || appKey.isEmpty) {
        throw Exception('PusherService: PUSHER_APP_KEY is not set');
      }

      if (cluster == null || cluster.isEmpty) {
        throw Exception('PusherService: Cluster not set in env');
      }

      _logger.d('Initializing with appKey: $appKey, cluster: $cluster');

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
        onAuthorizer: _onAuthorizer,
      );

      await _connectWithRetry();

      _isInitialized = true;
      _initStreamController.add(true);
      _logger.i('PusherService: Initialization successful');

      // Subscribe to channels concurrently
      await _subscribeToDefaultChannels();
      
      if (_currentUserId != null) {
        await _subscribeToUserChannel(_currentUserId!);
      }
    } catch (e, stackTrace) {
      _logger.e('PusherService: Initialization failed: $e\n$stackTrace');
      _isInitialized = false;
      _initStreamController.add(false);
      rethrow;
    }
  }

  void _onError(String message, int? code, dynamic e) {
  _logger.e(
    'PusherService Error - Message: $message, Code: $code, Exception: $e',
  );
  // You could add additional error handling logic here if needed
  // For example, triggering a reconnection on certain error codes
  if (code != null && code >= 4000) {
    _logger.w('PusherService: Critical error detected, attempting to reconnect...');
    if (!_isReconnecting && _pusher != null) {
      _isReconnecting = true;
      _pusher!.connect();
    }
  }
}

  Future<void> _connectWithRetry() async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        await _pusher!.connect();
        _logger.i('PusherService: Connection successful');
        return;
      } catch (e) {
        _logger.e('Connection attempt $attempt failed: $e');
        if (attempt == 3) throw Exception('Failed to connect after 3 attempts');
        await Future.delayed(Duration(seconds: attempt));
      }
    }
  }

  Future<void> _subscribeToDefaultChannels() async {
    _logger.d('PusherService: Subscribing to general channels...');
    try {
      await Future.wait([
        'ads',
        'posts',
        'gigs',
        'products',
        'notifications',
      ].map((channel) => subscribeToChannel(channel)));
    } catch (e) {
      _logger.e('Error subscribing to default channels: $e');
    }
  }

  Future<Map<String, dynamic>> _onAuthorizer(
    String channelName,
    String socketId,
    dynamic options,
  ) async {
    _logger.d('Authorizing channel $channelName with socketId $socketId');
    try {
      final authEndpoint = dotenv.env['PUSHER_AUTH_ENDPOINT'] ??
          'https://your-backend.com/pusher/auth';
      
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
        _logger.e('Authorization failed for $channelName: ${response.body}');
        throw Exception('Authorization failed: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Authorization error for $channelName: $e');
      rethrow;
    }
  }

  void _onConnectionStateChange(dynamic currentState, dynamic previousState) {
    _logger.i('Connection state changed from $previousState to $currentState');

    if (currentState == 'CONNECTED') {
      _isInitialized = true;
      _initStreamController.add(true);
      _isReconnecting = false;
      _logger.i('PusherService: Connected');
      // Let Pusher handle automatic resubscription
    } else if (currentState == 'DISCONNECTED') {
      _isInitialized = false;
      _initStreamController.add(false);
      _logger.w('PusherService: Disconnected');
    } else if (currentState == 'RECONNECTING') {
      _isReconnecting = true;
      _logger.i('PusherService: Reconnecting...');
    }
  }

  Future<void> _onGlobalEvent(PusherEvent event) async {
    if (_internalPusherEvents.contains(event.eventName)) {
      _logger.d('Received internal event "${event.eventName}"');
      return;
    }

    _logger.i('Received event "${event.eventName}" on "${event.channelName}"');

    final channelBindings = _eventBindings[event.channelName];
    if (channelBindings != null && channelBindings.containsKey(event.eventName)) {
      try {
        final parsedData = await _parseEventData(event.data);
        final modifiedEvent = PusherEvent(
          channelName: event.channelName,
          eventName: event.eventName,
          data: parsedData,
        );
        channelBindings[event.eventName]!(modifiedEvent);
      } catch (e) {
        _logger.e('Error processing ${event.eventName}: $e');
      }
    } else {
      _logger.w('No handler for ${event.eventName} on ${event.channelName}');
    }
  }

  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    _logger.i('Subscribed to channel: $channelName');
    _subscribedChannels[channelName] = true;
  }

  void _onSubscriptionError(String message, dynamic e) {
    _logger.e('Subscription error: $message, Exception: $e');
  }

  Future<void> _subscribeToUserChannel(String userId) async {
    final userChannelName = 'user.profile.$userId';
    await subscribeToChannel(userChannelName);
    _bindUserProfileEvents(userChannelName);
  }

  void _bindUserProfileEvents(String userChannelName) {
    bindToEvent(userChannelName, 'user.profile.updated', (event) async {
      try {
        final eventData = await _parseEventData(event.data);
        _logger.i('Received user.profile.updated: $eventData');
      } catch (e, stackTrace) {
        _logger.e('Error processing user.profile.updated: $e\n$stackTrace');
      }
    });
  }

  Future<void> subscribeToUserChannels(String userId) async {
    if (!_isInitialized || _pusher == null) {
      _logger.w('Not initialized. Cannot subscribe to user channels');
      return;
    }
    _currentUserId = userId;
    await _subscribeToUserChannel(userId);
  }

  Future<void> unsubscribeFromUserChannels() async {
    if (_currentUserId == null) return;
    final userChannelName = 'user.profile.$_currentUserId';
    await unsubscribeFromChannel(userChannelName);
    _currentUserId = null;
  }

  Future<bool> subscribeToChannel(String channelName) async {
    if (!_isInitialized || _pusher == null) {
      _logger.e('Not initialized. Cannot subscribe to $channelName');
      return false;
    }

    if (_subscribedChannels[channelName] == true) {
      _logger.d('Already subscribed to $channelName');
      return true;
    }

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        await _pusher!.subscribe(channelName: channelName);
        return true;
      } catch (e) {
        _logger.e('Subscription attempt $attempt failed: $e');
        if (attempt == 3) {
          _subscribedChannels[channelName] = false;
          return false;
        }
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    return false;
  }

  void bindToEvent(
    String channelName,
    String eventName,
    void Function(PusherEvent) onEvent,
  ) {
    _eventBindings.putIfAbsent(channelName, () => {})[eventName] = onEvent;
    _logger.i('Bound to $eventName on $channelName');
  }

  Future<void> unsubscribeFromChannel(String channelName) async {
    if (!_isInitialized || _pusher == null) {
      _logger.w('Not initialized. Cannot unsubscribe from $channelName');
      return;
    }

    if (_subscribedChannels[channelName] == true) {
      try {
        await _pusher!.unsubscribe(channelName: channelName);
        _subscribedChannels.remove(channelName);
        _eventBindings.remove(channelName);
        _logger.i('Unsubscribed from $channelName');
      } catch (e) {
        _logger.e('Error unsubscribing from $channelName: $e');
      }
    }
  }

  Future<void> disconnect() async {
    _logger.i('PusherService: Disconnecting...');
    _subscribedChannels.clear();
    _eventBindings.clear();
    if (_pusher != null) {
      await _pusher!.disconnect();
    }
    _isInitialized = false;
    _currentUserId = null;
    _initStreamController.add(false);
  }

  Future<void> resubscribeToChannels() async {
    if (!_isInitialized || _pusher == null) return;

    _logger.i('Resubscribing to channels...');
    final channelsToResubscribe = _subscribedChannels.keys.toList();
    
    await Future.wait(channelsToResubscribe.map((channel) => 
      subscribeToChannel(channel)
    ));

    if (_currentUserId != null) {
      await _subscribeToUserChannel(_currentUserId!);
    }
  }

  Future<Channel?> subscribeToChannelCompat(String channelName) async {
    final success = await subscribeToChannel(channelName);
    return success ? Channel(channelName) : null;
  }

  void dispose() {
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