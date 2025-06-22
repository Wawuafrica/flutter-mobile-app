import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Provides app-wide network status and events for online/offline transitions.
class NetworkStatusProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _wasOffline = false;
  bool _hasInitialized = false;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  bool get isOnline => _isOnline;
  bool get wasOffline => _wasOffline;
  bool get hasInitialized => _hasInitialized;

  NetworkStatusProvider() {
    _init();
  }

  void _init() async {
    try {
      // Get initial connectivity status
      final results = await Connectivity().checkConnectivity();
      _updateStatus(results, isInitial: true);

      // Listen for connectivity changes
      _subscription = Connectivity().onConnectivityChanged.listen((results) {
        _updateStatus(results, isInitial: false);
      });

      _hasInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('NetworkStatusProvider: Error initializing: $e');
      _hasInitialized = true;
      notifyListeners();
    }
  }

  void _updateStatus(
    List<ConnectivityResult> results, {
    required bool isInitial,
  }) {
    final online = results.any((r) => r != ConnectivityResult.none);

    if (_isOnline != online) {
      final wasOnlineBefore = _isOnline;
      _isOnline = online;

      // Only set _wasOffline if we're coming back online after being offline
      // and this is not the initial check
      if (!isInitial && !wasOnlineBefore && online) {
        _wasOffline = true;
        debugPrint(
          'NetworkStatusProvider: Network reconnected - setting wasOffline to true',
        );

        // Reset _wasOffline after notifying listeners
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _wasOffline = false;
            notifyListeners();
          });
        });
      }

      debugPrint(
        'NetworkStatusProvider: Status changed - isOnline: $_isOnline, wasOffline: $_wasOffline',
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
