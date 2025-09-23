// NEW FILE
// Manages the connection to the Socket.IO server for real-time updates.

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'dart:async';

class SocketService {
  IO.Socket? _socket;
  final _socketResponseController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Expose stream for other services to listen to
  Stream<Map<String, dynamic>> get socketResponseStream => _socketResponseController.stream;

  // Private constructor for singleton pattern
  SocketService._internal();
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  void initializeSocket(String token) {
    // Prevent re-initialization
    if (_socket != null && _socket!.connected) {
        debugPrint('SOCKET_SERVICE: Socket already initialized and connected.'); // MODIFIED
        return;
    }
    
    final socketUrl = 'https://ts.wawuafrica.com';
    debugPrint('SOCKET_SERVICE: Initializing socket connection to $socketUrl...'); // MODIFIED

    try {
      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'forceNew': true, // Ensures a new connection is made
        'extraHeaders': {
          'Authorization': 'Bearer $token',
          'channel': 'user'
          }
      });

      _socket!.connect();

      _socket!.onConnect((_) {
        debugPrint('✅ SOCKET_SERVICE: Socket connected successfully with ID: ${_socket!.id}'); // MODIFIED
      });

      _socket!.onDisconnect((_) {
        debugPrint('🔌 SOCKET_SERVICE: Socket disconnected'); // MODIFIED
      });

      _socket!.onConnectError((data) {
        debugPrint('❌ SOCKET_SERVICE: Socket connection error: $data'); // MODIFIED
      });

      _socket!.onError((data) {
        debugPrint('❌ SOCKET_SERVICE: Socket error: $data'); // MODIFIED
      });

      // Listen to all relevant events and push them to the stream
      _listenToEvents();

    } catch (e) {
      debugPrint('❌ SOCKET_SERVICE: Error initializing socket: $e'); // MODIFIED
    }
  }
  
  void _listenToEvents() {
    if (_socket == null) return;
    
    // List of events from the backend
    const events = ['new_comment', 'updated_comment', 'deleted_comment', 'like_update'];
    
    for (var event in events) {
      _socket!.on(event, (data) {
        debugPrint('↘️ SOCKET_SERVICE: Received event [$event] with data: $data'); // ADD THIS LOG
        _socketResponseController.add({'event': event, 'data': data});
      });
    }
  }

  void joinContentRoom(int contentId) {
    if (_socket != null && _socket!.connected) {
      final roomName = 'content-$contentId';
      debugPrint('↗️ SOCKET_SERVICE: Joining room: $roomName'); // MODIFIED
      _socket!.emit('join_content_room', contentId);
    }
  }

  void leaveContentRoom(int contentId) {
    if (_socket != null && _socket!.connected) {
      final roomName = 'content-$contentId';
      debugPrint('↗️ SOCKET_SERVICE: Leaving room: $roomName'); // MODIFIED
      _socket!.emit('leave_content_room', contentId);
    }
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socketResponseController.close();
  }
}