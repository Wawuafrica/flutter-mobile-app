import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Provides app-wide network status and events for online/offline transitions.
class NetworkStatusProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _wasOffline =
      false; // Tracks if the app was previously offline and is now online
  bool _hasInitialized = false;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  // Getters
  bool get isOnline => _isOnline;
  bool get wasOffline => _wasOffline;
  bool get hasInitialized => _hasInitialized;

  NetworkStatusProvider() {
    _init();
  }

  void _init() {
    // No need for _isInitializing flag if we initialize immediately
    // and rely on _hasInitialized for external checks.

    // Get initial connectivity status
    Connectivity()
        .checkConnectivity()
        .then((results) {
          _updateStatus(results);
          _hasInitialized = true;
          notifyListeners(); // Notify listeners after initial status is set
        })
        .catchError((e) {
          debugPrint(
            'NetworkStatusProvider: Error checking initial connectivity: $e',
          );
          _hasInitialized = true;
          notifyListeners(); // Still notify even on error to unblock UI if needed
        });

    // Listen for connectivity changes
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (_hasDisposed) return;

    final bool newOnlineStatus = results.any(
      (r) => r != ConnectivityResult.none,
    );

    // Only update and notify if the status has actually changed
    if (_isOnline != newOnlineStatus) {
      // If we were offline and are now online, set _wasOffline to true
      if (!_isOnline && newOnlineStatus) {
        _wasOffline = true;
        debugPrint(
          'NetworkStatusProvider: Network reconnected. Setting _wasOffline to true.',
        );
      } else {
        _wasOffline =
            false; // Reset _wasOffline if going offline or staying online
      }

      _isOnline = newOnlineStatus;
      debugPrint(
        'NetworkStatusProvider: Status changed - isOnline: $_isOnline, wasOffline: $_wasOffline',
      );
      notifyListeners(); // Notify immediately on status change
    }
  }

  bool _hasDisposed = false;

  @override
  void dispose() {
    _hasDisposed = true;
    _subscription.cancel();
    super.dispose();
  }
}
