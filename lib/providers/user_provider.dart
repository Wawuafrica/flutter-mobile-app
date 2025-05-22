import 'dart:convert';
import 'dart:io'; // For File type

import 'package:dio/dio.dart' as dio; // For FormData

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
  }) : _authService = authService,
       _apiService = apiService,
       _pusherService = pusherService,
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
          await _subscribeToUserChannel();
          setSuccess();
        } else {
          await _authService
              .logout(); // Clear potentially inconsistent auth state
          setError('Failed to load user session.');
        }
      } catch (e) {
        setError(e.toString());
        await _authService.logout(); // Clear auth state on error
      }
    }
  }

  Future<void> login(String email, String password) async {
    try {
      _currentUser = await _authService.login(email, password);
      if (_currentUser != null) {
        await _subscribeToUserChannel();
      }
    } catch (e) {
      setError('Login failed');
    }
  }

  Future<void> register(Map<String, dynamic> userData) async {
    try {
      // Registration in AuthService might or might not auto-login (save token).
      // Assuming it does if successful and token is part of response.
      _currentUser = await _authService.register(userData);
      if (_authService.isAuthenticated && _currentUser != null) {
        await _subscribeToUserChannel();
      } else {
        // UI should likely redirect to login or show a message
      }
    } catch (e) {
      setError('Registration failed');
    }
  }

  Future<void> fetchCurrentUser() async {
    if (!_authService.isAuthenticated) {
      _currentUser = null;
      resetState();
      return;
    }
    try {
      _currentUser = await _authService.getCurrentUserProfile();
      if (_currentUser != null) {
        await _subscribeToUserChannel();
      }
    } catch (e) {
      setError('Failed to fetch user data');
    }
  }

  Future<void> fetchUserById(String userId) async {
    try {
      final response = await _apiService.get('/api/user/$userId');
      if (response != null && response['data'] != null) {
        _viewedUser = User.fromJson(response['data'] as Map<String, dynamic>);
      } else {
        throw Exception(
          response?['message'] as String? ??
              'Failed to fetch user profile by ID',
        );
      }
    } catch (e) {
      setError('Failed to fetch user profile');
    }
  }

  Future<void> _subscribeToUserChannel() async {
    if (_currentUser == null || _currentUser!.uuid.isEmpty) {
      return;
    }
    // Unsubscribe from any previous channel first
    // This needs a mechanism if the user ID could change or on logout.
    // For now, assuming UserProvider is re-created or dispose handles old subscriptions.

    final channelName = 'user-${_currentUser!.uuid}';
    try {
      final channel = await _pusherService.subscribeToChannel(channelName);
      if (channel != null) {
        _pusherService.bindToEvent(channelName, 'profile-updated', (data) {
          if (data is String) {
            try {
              final eventData = jsonDecode(data) as Map<String, dynamic>;
              // Ensure the event data is for the current user if not already guaranteed by channel
              if (eventData['uuid'] == _currentUser!.uuid) {
                _currentUser = User.fromJson(
                  eventData,
                ); // Assuming event data is a full User object
                notifyListeners();
              }
            } catch (e) {
              print('Error processing profile-updated event: $e. Data: $data');
            }
          }
        });
      } else {
        print('Failed to subscribe to Pusher channel: $channelName. Channel is null.');
      }
    } catch (e) {
      print('Error subscribing or binding to Pusher channel $channelName: $e');
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

    try {
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
      } else {
        throw Exception(
          response?['message'] as String? ?? 'Failed to update profile',
        );
      }
    } catch (e) {
      setError('Failed to update profile');
    }
  }

  Future<void> logout() async {
    final String? userIdForPusher = _currentUser?.uuid;
    try {
      await _authService.logout();
      _currentUser = null;
      _viewedUser = null; // Clear viewed user on logout
      if (userIdForPusher != null && userIdForPusher.isNotEmpty) {
        await _pusherService.unsubscribeFromChannel('user-$userIdForPusher');
      }
    } catch (e) {
      setError('Logout failed');
    }
  }

  // OTP and Password Reset methods - can be called directly from UI or through UserProvider
  Future<void> sendOtp(String email, {String? type}) async {
    try {
        await _authService.sendOtp(email, type: type);
    } catch (e) {
      setError('Failed to send OTP');
    }
    
  }

  Future<void> verifyOtp(String email, String otp, {String? type}) async {
     try {
       await _authService.verifyOtp(email, otp, type: type);
     } catch (e) {
        setError('Failed to verify OTP');
     }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _authService.forgotPassword(email);
    } catch (e) {
      setError('Failed to send password reset instructions');
    }
  }

  Future<void> resetPassword(
    String email,
    String otp,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
       await
          _authService.resetPassword(email, otp, newPassword, confirmPassword);
    } catch (e) {
       setError('Failed to reset password');
    }
   
  }

  @override
  void dispose() {
    if (_currentUser != null && _currentUser!.uuid.isNotEmpty) {
      _pusherService.unsubscribeFromChannel('user-${_currentUser!.uuid}');
    }
    super.dispose();
  }
}
