import 'dart:convert';
import 'dart:io'; // For File type

import 'package:dio/dio.dart' as dio; // For FormData
import 'package:logger/logger.dart';

import '../models/user.dart'; // Use the new User model
import '../services/auth_service.dart';
import '../services/api_service.dart'; // Still needed for non-auth user actions if any, or for direct injection into AuthService
import '../services/pusher_service.dart';
import 'base_provider.dart';

class UserProvider extends BaseProvider {
  final AuthService _authService;
  final ApiService
  _apiService; // For potential direct user-related API calls not part of auth
  final PusherService _pusherService;
  final Logger _logger;

  User? _currentUser;
  User? _viewedUser; // For storing a fetched user profile
  // _isAuthenticated can be derived from _authService.isAuthenticated or _currentUser != null
  bool get isAuthenticated =>
      _authService.isAuthenticated && _currentUser != null;
  User? get currentUser => _currentUser;
  User? get viewedUser => _viewedUser;

  UserProvider({
    required AuthService authService,
    required ApiService apiService,
    required PusherService pusherService,
    required Logger logger,
  }) : _authService = authService,
       _apiService = apiService,
       _pusherService = pusherService,
       _logger = logger,
       super() {
    _loadInitialUser();
  }

  Future<void> _loadInitialUser() async {
    if (_authService.isAuthenticated) {
      setLoading();
      try {
        _currentUser = await _authService.getUser(); // Get user from storage
        if (_currentUser == null) {
          // If not in storage, try fetching from API
          _currentUser = await _authService.getCurrentUserProfile();
        }
        if (_currentUser != null) {
          _logger.i('User loaded from session: ${_currentUser!.email}');
          await _subscribeToUserChannel();
          setSuccess();
        } else {
          _logger.w(
            'Could not load user from session or API after auth check.',
          );
          await _authService
              .logout(); // Clear potentially inconsistent auth state
          setError('Failed to load user session.');
        }
      } catch (e) {
        _logger.e('Failed to load initial user: $e');
        setError(e.toString());
        await _authService.logout(); // Clear auth state on error
      }
    }
  }

  Future<void> login(String email, String password) async {
    await handleAsync(() async {
      _currentUser = await _authService.login(email, password);
      if (_currentUser != null) {
        _logger.i('Login successful for: ${_currentUser!.email}');
        await _subscribeToUserChannel();
      }
      return _currentUser;
    }, errorMessage: 'Login failed');
  }

  Future<void> register(Map<String, dynamic> userData) async {
    await handleAsync(() async {
      // Registration in AuthService might or might not auto-login (save token).
      // Assuming it does if successful and token is part of response.
      _currentUser = await _authService.register(userData);
      if (_authService.isAuthenticated && _currentUser != null) {
        _logger.i('User logged in after registration: ${_currentUser!.email}');
        await _subscribeToUserChannel();
      } else {
        _logger.i(
          'User registered. Further action may be needed (e.g., verification, login).',
        );
        // UI should likely redirect to login or show a message
      }
      return _currentUser; // Return user data whether logged in or not for UI to decide next step
    }, errorMessage: 'Registration failed');
  }

  Future<void> fetchCurrentUser() async {
    if (!_authService.isAuthenticated) {
      _logger.w('Attempted to fetch current user when not authenticated.');
      _currentUser = null;
      resetState();
      return;
    }
    await handleAsync(() async {
      _currentUser = await _authService.getCurrentUserProfile();
      if (_currentUser != null) {
        _logger.i('Current user profile fetched: ${_currentUser!.email}');
        await _subscribeToUserChannel();
      }
      return _currentUser;
    }, errorMessage: 'Failed to fetch user data');
  }

  Future<void> fetchUserById(String userId) async {
    await handleAsync(() async {
      _logger.i('Fetching profile for user ID: $userId');
      final response = await _apiService.get('/api/user/$userId');
      if (response != null && response['data'] != null) {
        _viewedUser = User.fromJson(response['data'] as Map<String, dynamic>);
        _logger.i('Fetched profile for user: ${_viewedUser?.email}');
        return _viewedUser;
      } else {
        _logger.w('Get user by ID response missing data: $response');
        throw Exception(
          response?['message'] as String? ??
              'Failed to fetch user profile by ID',
        );
      }
    }, errorMessage: 'Failed to fetch user profile');
  }

  Future<void> _subscribeToUserChannel() async {
    if (_currentUser == null || _currentUser!.uuid.isEmpty) {
      _logger.w(
        'Cannot subscribe to user channel: current user or user UUID is null/empty.',
      );
      return;
    }
    // Unsubscribe from any previous channel first
    // This needs a mechanism if the user ID could change or on logout.
    // For now, assuming UserProvider is re-created or dispose handles old subscriptions.

    final channelName = 'user-${_currentUser!.uuid}';
    try {
      _logger.i('Subscribing to Pusher channel: $channelName');
      final channel = await _pusherService.subscribeToChannel(channelName);
      if (channel != null) {
        _pusherService.bindToEvent(channelName, 'profile-updated', (data) {
          _logger.i('Received profile-updated event: $data');
          if (data is String) {
            try {
              final eventData = jsonDecode(data) as Map<String, dynamic>;
              // Ensure the event data is for the current user if not already guaranteed by channel
              if (eventData['uuid'] == _currentUser!.uuid) {
                _currentUser = User.fromJson(
                  eventData,
                ); // Assuming event data is a full User object
                notifyListeners();
                _logger.i(
                  'User profile updated via Pusher: ${_currentUser!.email}',
                );
              } else {
                _logger.w(
                  'Received profile-updated event for different user: ${eventData['uuid']}',
                );
              }
            } catch (e) {
              _logger.e(
                'Error processing profile-updated event: $e. Data: $data',
              );
            }
          } else {
            _logger.w(
              'Received profile-updated event with unexpected data type: ${data.runtimeType}',
            );
          }
        });
      } else {
        _logger.w(
          'Failed to subscribe to Pusher channel: $channelName. Channel is null.',
        );
      }
    } catch (e) {
      _logger.e(
        'Error subscribing or binding to Pusher channel $channelName: $e',
      );
    }
  }

  // Takes a map of data. For file uploads, the caller should prepare FormData if ApiService requires it.
  Future<void> updateCurrentUserProfile(
    Map<String, dynamic> profileData, {
    File? profileImageFile,
    File? coverImageFile,
  }) async {
    if (!_authService.isAuthenticated || _currentUser == null) {
      setError('User not authenticated for profile update');
      return;
    }

    await handleAsync(() async {
      _logger.i(
        'Attempting to update current user profile with data: $profileData',
      );

      // Construct FormData
      final formDataMap = {...profileData}; // Start with text fields

      if (profileImageFile != null) {
        formDataMap['profileImage'] = await dio.MultipartFile.fromFile(
          profileImageFile.path,
        );
      }
      if (coverImageFile != null) {
        formDataMap['coverImage'] = await dio.MultipartFile.fromFile(
          coverImageFile.path,
        );
      }
      // TODO: Handle other potential file fields like 'meansOfIdentification[file]', 'professionalCertification[0][file]' etc.
      // This would require a more complex data structure for `profileData` or more specific parameters.

      final dio.FormData formData = dio.FormData.fromMap(formDataMap);

      final response = await _apiService.post(
        '/api/user/profile/update',
        data: formData,
        // ApiService.post needs to be able to handle FormData, potentially by setting content type.
        // options: dio.Options(contentType: 'multipart/form-data'), // This might be needed in ApiService
      );

      if (response != null && response['data'] != null) {
        _currentUser = User.fromJson(response['data'] as Map<String, dynamic>);
        await _authService
            .getUser(); // To re-save/update the user in SharedPreferences via AuthService
        _logger.i(
          'Current User Profile updated successfully for: ${_currentUser!.email}',
        );
        return _currentUser;
      } else {
        _logger.w(
          'Update current user profile response missing data or failed: $response',
        );
        throw Exception(
          response?['message'] as String? ?? 'Failed to update profile',
        );
      }
    }, errorMessage: 'Failed to update profile');
  }

  Future<void> logout() async {
    final String? userIdForPusher = _currentUser?.uuid;
    await handleAsync(() async {
      await _authService.logout();
      _currentUser = null;
      _viewedUser = null; // Clear viewed user on logout
      if (userIdForPusher != null && userIdForPusher.isNotEmpty) {
        _logger.i('Unsubscribing from Pusher channel: user-$userIdForPusher');
        await _pusherService.unsubscribeFromChannel('user-$userIdForPusher');
      }
      _logger.i('User logged out successfully from UserProvider.');
      return true;
    }, errorMessage: 'Logout failed');
  }

  // OTP and Password Reset methods - can be called directly from UI or through UserProvider
  Future<void> sendOtp(String email, {String? type}) async {
    await handleAsync(
      () => _authService.sendOtp(email, type: type),
      errorMessage: 'Failed to send OTP',
    );
    if (!hasError) _logger.i('OTP sent successfully to $email');
  }

  Future<void> verifyOtp(String email, String otp, {String? type}) async {
    await handleAsync(
      () => _authService.verifyOtp(email, otp, type: type),
      errorMessage: 'Failed to verify OTP',
    );
    if (!hasError) _logger.i('OTP verified successfully for $email');
  }

  Future<void> forgotPassword(String email) async {
    await handleAsync(
      () => _authService.forgotPassword(email),
      errorMessage: 'Failed to send password reset instructions',
    );
    if (!hasError) _logger.i('Password reset instructions sent to $email');
  }

  Future<void> resetPassword(
    String email,
    String otp,
    String newPassword,
    String confirmPassword,
  ) async {
    await handleAsync(
      () =>
          _authService.resetPassword(email, otp, newPassword, confirmPassword),
      errorMessage: 'Failed to reset password',
    );
    if (!hasError) _logger.i('Password reset successfully for $email');
  }

  @override
  void dispose() {
    if (_currentUser != null && _currentUser!.uuid.isNotEmpty) {
      _pusherService.unsubscribeFromChannel('user-${_currentUser!.uuid}');
    }
    super.dispose();
  }
}
