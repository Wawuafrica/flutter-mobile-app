import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Provides app-wide network status and events for online/offline transitions.
class NetworkStatusProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _wasOffline = false;
  bool _hasInitialized = false;
  bool _isInitializing = false;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  Timer? _debounceTimer;

  bool get isOnline => _isOnline;
  bool get wasOffline => _wasOffline;
  bool get hasInitialized => _hasInitialized;

  NetworkStatusProvider() {
    _init();
  }

  void _init() {
    if (_isInitializing) return;
    _isInitializing = true;

    // Use microtask to prevent blocking the constructor
    scheduleMicrotask(() async {
      try {
        // Get initial connectivity status
        final results = await Connectivity().checkConnectivity();
        _updateStatus(results, isInitial: true);

        // Listen for connectivity changes
        _subscription = Connectivity().onConnectivityChanged.listen((results) {
          _updateStatus(results, isInitial: false);
        });

        _hasInitialized = true;
        _isInitializing = false;

        // Use microtask to prevent blocking
        scheduleMicrotask(() {
          if (!_hasDisposed) notifyListeners();
        });
      } catch (e) {
        debugPrint('NetworkStatusProvider: Error initializing: $e');
        _hasInitialized = true;
        _isInitializing = false;

        scheduleMicrotask(() {
          if (!_hasDisposed) notifyListeners();
        });
      }
    });
  }

  bool _hasDisposed = false;

  void _updateStatus(
    List<ConnectivityResult> results, {
    required bool isInitial,
  }) {
    if (_hasDisposed) return;

    // Debounce rapid connectivity changes
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _processStatusUpdate(results, isInitial: isInitial);
    });
  }

  void _processStatusUpdate(
    List<ConnectivityResult> results, {
    required bool isInitial,
  }) {
    if (_hasDisposed) return;

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

        // Reset _wasOffline after a short delay using microtask
        Timer(const Duration(seconds: 3), () {
          // Changed from 100 milliseconds to 3 seconds
          if (!_hasDisposed) {
            _wasOffline = false;
            scheduleMicrotask(() {
              if (!_hasDisposed) notifyListeners();
            });
          }
        });
      }

      debugPrint(
        'NetworkStatusProvider: Status changed - isOnline: $_isOnline, wasOffline: $_wasOffline',
      );

      // Use microtask to prevent UI blocking
      scheduleMicrotask(() {
        if (!_hasDisposed) notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _hasDisposed = true;
    _debounceTimer?.cancel();
    _subscription.cancel();
    super.dispose();
  }
}
