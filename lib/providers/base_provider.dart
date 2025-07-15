import 'package:flutter/foundation.dart';

enum LoadingState { idle, loading, error, success }

class BaseProvider extends ChangeNotifier {
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
    _errorMessage = message;
    _setState(LoadingState.error);
  }

  @protected
  void setSuccess() {
    _errorMessage = null;
    _setState(LoadingState.success);
    notifyListeners();
  }

  @protected
  void resetState() {
    _errorMessage = null;
    _setState(LoadingState.idle);
    notifyListeners();
  }

  void _setState(LoadingState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
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
