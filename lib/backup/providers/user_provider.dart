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
    }, errorMessage: 'Failed to fetch current user');
  }

  Future<void> fetchUserById(String userId) async {
    await handleAsync(() async {
      final response = await _apiService.get(
        '/api/users/$userId',
      );
      if (response != null && response['data'] != null) {
        _viewedUser = User.fromJson(response['data'] as Map<String, dynamic>);
        _logger.i('User profile fetched for ID: $userId');
        return _viewedUser;
      } else {
        _logger.w('User profile response missing data: $response');
        _viewedUser = null;
        throw Exception(
          response?['message'] as String? ?? 'Failed to fetch user',
        );
      }
    }, errorMessage: 'Failed to fetch user');
  }

  Future<void> _subscribeToUserChannel() async {
    if (_currentUser == null || _currentUser!.uuid.isEmpty) {
      _logger.w('Cannot subscribe to user channel: No user ID available.');
      return;
    }
    try {
      final String channelName = 'user-${_currentUser!.uuid}';
      final channel = await _pusherService.subscribeToChannel(channelName);

      if (channel != null) {
        // Bind to notification events
        _pusherService.bindToEvent(
          channelName,
          'notification',
          (data) {
            try {
              final jsonData = jsonDecode(data as String) as Map<String, dynamic>;
              _logger.i('Received notification: $jsonData');
              // You would likely want to:
              // 1. Update notification count locally
              // 2. Possibly show a local notification
              // 3. Update notification list if that view is active
              // This could trigger a call to a NotificationProvider's methods
            } catch (e) {
              _logger.e('Error parsing notification data: $e');
            }
          },
        );

        // Bind to message events
        _pusherService.bindToEvent(
          channelName,
          'message',
          (data) {
            try {
              final jsonData = jsonDecode(data as String) as Map<String, dynamic>;
              _logger.i('Received message: $jsonData');
              // Similar pattern to notification handling:
              // 1. Update unread count for relevant conversation
              // 2. Show notification if app in background
              // 3. Update chat UI if conversation is open
              // This could trigger a call to a MessageProvider's methods
            } catch (e) {
              _logger.e('Error parsing message data: $e');
            }
          },
        );

        // Add more event bindings for other real-time updates
        _logger.i('Successfully bound to events for user channel: $channelName');
      }
    } catch (e) {
      _logger.e('Error subscribing to user channel: $e');
      // Not rethrowing as this is non-critical
    }
  }

  Future<void> updateCurrentUserProfile(
    Map<String, dynamic> profileData, {
    File? profileImageFile,
    File? coverImageFile,
  }) async {
    if (!isAuthenticated) {
      _logger.w('Attempted to update profile when not authenticated.');
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
