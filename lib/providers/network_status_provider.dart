import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Provides app-wide network status and events for online/offline transitions.
class NetworkStatusProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _wasOffline = false;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  bool get isOnline => _isOnline;
  bool get wasOffline => _wasOffline;

  NetworkStatusProvider() {
    _init();
  }

  void _init() async {
    final results = await Connectivity().checkConnectivity();
    _updateStatus(results);
    _subscription = Connectivity().onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (_isOnline != online) {
      _wasOffline = !_isOnline && online;
      _isOnline = online;
      notifyListeners();
      // After notifying, reset _wasOffline so it's only true for one frame
      if (_wasOffline) {
        Future.delayed(Duration(milliseconds: 100), () {
          _wasOffline = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
