import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'base_provider.dart'; // Import BaseProvider

/// Provides app-wide network status and events for online/offline transitions.
// NetworkStatusProvider now extends BaseProvider for architectural consistency.
class NetworkStatusProvider extends BaseProvider {
  // Removed _isOnline, _hasInitialized as BaseProvider's state will represent this.
  // _wasOffline is retained as it's a specific flag not directly covered by BaseProvider's state.
  bool _wasOffline =
      false; // Tracks if the app was previously offline and is now online
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  // Getters for isOnline, hasError, errorMessage are inherited from BaseProvider.
  // We can derive isOnline from BaseProvider's state.
  // @override
  bool get isOnline => !hasError; // If there's no error, assume online
  bool get wasOffline => _wasOffline;
  // hasInitialized is now implicitly managed by the initial state of the provider
  // or can be derived from the state of the first connectivity check.
  // bool get hasInitialized => _hasInitialized;

  NetworkStatusProvider() {
    _init();
  }

  void _init() {
    // Set initial state to loading while checking connectivity
    setLoading();

    // Get initial connectivity status
    Connectivity()
        .checkConnectivity()
        .then((results) {
          _updateStatus(results);
          // After initial check, consider the provider initialized.
          // BaseProvider's setSuccess/setError will notify listeners.
        })
        .catchError((e) {
          debugPrint(
            'NetworkStatusProvider: Error checking initial connectivity: $e',
          );
          // If there's an error checking connectivity, set the error state.
          setError('Failed to check initial network status: ${e.toString()}');
        });

    // Listen for connectivity changes
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // No need for _hasDisposed check here, BaseProvider's dispose handles it.

    final bool newOnlineStatus = results.any(
      (r) => r != ConnectivityResult.none,
    );

    // Only update and notify if the status has actually changed
    // Use BaseProvider's state for _isOnline check
    if (isOnline != newOnlineStatus) {
      // If we were offline and are now online, set _wasOffline to true
      if (!isOnline && newOnlineStatus) {
        // Use inherited isOnline
        _wasOffline = true;
        debugPrint(
          'NetworkStatusProvider: Network reconnected. Setting _wasOffline to true.',
        );
        setSuccess(); // Network is back online, set success state
      } else if (isOnline && !newOnlineStatus) {
        // Going offline
        _wasOffline = false; // Reset _wasOffline if going offline
        setError("You are currently offline."); // Set error state for offline
      } else {
        // Status remains the same (either online or offline), no state change needed for BaseProvider
        // but notify listeners if _wasOffline changes or for other internal updates.
        // For example, if staying online, just ensure state is success.
        if (newOnlineStatus) {
          setSuccess();
        }
      }

      debugPrint(
        'NetworkStatusProvider: Status changed - isOnline: $newOnlineStatus, wasOffline: $_wasOffline',
      );
      // BaseProvider's setSuccess/setError will call notifyListeners().
      // No need for manual notifyListeners() here.
    }
  }

  // bool _hasDisposed = false; // Removed as BaseProvider handles this

  @override
  void dispose() {
    // _hasDisposed = true; // Removed as BaseProvider handles this
    _subscription.cancel();
    super.dispose(); // Call super.dispose() to handle BaseProvider's disposal
  }
}
