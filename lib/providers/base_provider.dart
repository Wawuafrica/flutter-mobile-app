import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

enum LoadingState { idle, loading, error, success }

class BaseProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  LoadingState _state = LoadingState.idle;
  String? _errorMessage;
  bool _disposed = false;

  LoadingState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == LoadingState.loading;
  bool get hasError => _state == LoadingState.error;
  bool get isSuccess => _state == LoadingState.success;

  @protected
  void setLoading() {
    _setState(LoadingState.loading);
    _errorMessage = null;
  }

  @protected
  void setError(String message) {
    _logger.e(message);
    _errorMessage = message;
    _setState(LoadingState.error);
  }

  @protected
  void setSuccess() {
    _errorMessage = null;
    _setState(LoadingState.success);
  }

  @protected
  void resetState() {
    _errorMessage = null;
    _setState(LoadingState.idle);
  }

  void _setState(LoadingState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  @protected
  Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    String loadingMessage = 'Loading...',
    String? errorMessage,
  }) async {
    try {
      setLoading();
      final result = await operation();
      setSuccess();
      return result;
    } catch (e) {
      _logger.e('Error in ${runtimeType.toString()}');
      setError(errorMessage ?? e.toString());
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
