// lib/providers/user_provider.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio; // Use alias to avoid conflict with dart:io.File
import 'dart:io'; // For File
import 'dart:convert'; // For jsonDecode if needed for Pusher event data

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/pusher_service.dart'; // Assuming you have this service

class UserProvider extends ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;
  final PusherService _pusherService;

  // Internal state for the current user, synchronized with AuthService
  User? _currentUser;
  User? _viewedUser; // For viewing other user profiles

  // State flags for UI feedback
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isSuccess = false;
  String? _userChannelName; // To keep track of the current Pusher channel

  // Constructor
  UserProvider({
    required ApiService apiService,
    required AuthService authService,
    required PusherService pusherService,
  }) : _apiService = apiService,
       _authService = authService,
       _pusherService = pusherService {
    // Initialize current user from AuthService on provider creation
    // This is safe because AuthService.init() will have already been called (e.g., in main)
    _currentUser = _authService.currentUser;
    if (_currentUser != null && _authService.isAuthenticated) {
      // If user is already logged in (e.g., on app restart), subscribe to Pusher
      _subscribeToUserChannel();
    }
  }

  // Getters for UI to consume
  User? get currentUser => _currentUser;
  User? get viewedUser => _viewedUser;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;
  bool get isAuthenticated => _authService.isAuthenticated; // Delegate to AuthService

  // --- State Management Helpers ---
  void setLoading() {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();
  }

  void setError(String message) {
    _isLoading = false;
    _hasError = true;
    _errorMessage = message;
    _isSuccess = false;
    notifyListeners();
  }

  void setSuccess() {
    _isLoading = false;
    _hasError = false;
    _errorMessage = null;
    _isSuccess = true;
    notifyListeners();
  }

  void resetState() {
    _isLoading = false;
    _hasError = false;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();
  }

  // --- User Authentication/Session Management ---

  // Assuming login/register from auth service will return a User object
  Future<void> login(String email, String password) async {
    setLoading();
    try {
      _currentUser = await _authService.signIn(email, password); // Use signIn
      if (_currentUser != null) {
        await _subscribeToUserChannel();
        setSuccess();
      } else {
        setError('Login failed: User object is null.');
      }
    } on AuthException catch (e) {
      setError(e.message);
    } catch (e) {
      setError('An unexpected error occurred during login: ${e.toString()}');
    }
  }

  Future<void> register(Map<String, dynamic> userData) async {
    setLoading();
    try {
      _currentUser = await _authService.register(userData);
      if (_authService.isAuthenticated && _currentUser != null) {
        await _subscribeToUserChannel();
        setSuccess();
      } else {
        setError('Registration successful but failed to log in automatically.');
      }
    } on AuthException catch (e) {
      setError(e.message);
    } catch (e) {
      setError('An unexpected error occurred during registration: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    setLoading();
    try {
      if (_userChannelName != null) {
        await _pusherService.unsubscribeFromChannel(_userChannelName!);
        _userChannelName = null;
      }
      await _authService.logout(); // Clears token and user locally
      _currentUser = null;
      _viewedUser = null; // Clear viewed user too
      setSuccess();
      print('User logged out successfully.');
    } on AuthException catch (e) {
      setError(e.message);
    } catch (e) {
      setError('Logout failed: ${e.toString()}');
    } finally {
      // Ensure state is reset even if error occurs
      _currentUser = null;
      _viewedUser = null;
      resetState();
    }
  }

  Future<void> fetchCurrentUser() async {
    if (!_authService.isAuthenticated) {
      _currentUser = null; // Ensure current user is null if not authenticated
      resetState();
      print('Attempted to fetch current user when not authenticated.');
      return;
    }
    setLoading();
    try {
      // AuthService fetches and saves the user internally
      _currentUser = await _authService.getCurrentUserProfile();
      if (_currentUser != null) {
        await _subscribeToUserChannel(); // Re-subscribe if user was re-fetched
        setSuccess();
      } else {
        setError('Failed to fetch user profile: User is null after fetch.');
      }
    } on AuthException catch (e) {
      setError(e.message);
    } catch (e) {
      setError('An unexpected error occurred while fetching user profile: ${e.toString()}');
    }
  }

  // --- Account Type Onboarding ---
  // This method specifically handles the /user/onboard/:user_id endpoint
  Future<void> updateAccountType(int roleValue) async {
    if (!_authService.isAuthenticated || _authService.currentUser == null || _authService.currentUser!.uuid.isEmpty) {
      setError('User not authenticated or UUID missing for account type update.');
      return;
    }

    setLoading();
    try {
      final response = await _apiService.post(
        '/user/onboard/${_authService.currentUser!.uuid}', // Correct endpoint with UUID from AuthService
        data: {'role': roleValue}, // Send the integer role value as per backend
      );

      if (response['statusCode'] == 200 && response.containsKey('data')) {
        // Assuming the 'data' field directly contains the updated user object
        final updatedUser = User.fromJson(response['data'] as Map<String, dynamic>);
        // Update _currentUser with the new data. Use copyWith to ensure immutability is handled well.
        // It's crucial that the User.fromJson correctly maps the 'role' string (e.g., "PROFESSIONAL")
        // to the 'role' field in your User model.
        _currentUser = updatedUser;
        await _authService.saveUser(_currentUser!); // Persist updated user data locally via AuthService

        setSuccess();
        print('Account Type updated successfully for: ${_currentUser!.email} to role: ${_currentUser!.role}');
      } else {
        final message = response['message'] as String? ?? 'Failed to update account type: Invalid response structure.';
        setError(message);
      }
    } on dio.DioError catch (e) {
      setError(AuthService.extractErrorMessage(e));
    } catch (e) {
      setError('Failed to update account type: ${e.toString()}');
    }
  }

  // --- General User Profile Update ---
  // This method is distinct and handles other general profile fields, potentially
  // using a different API endpoint.
  Future<void> updateCurrentUserProfile(
    Map<String, dynamic> profileData, {
    File? profileImageFile,
    File? coverImageFile,
  }) async {
    if (!_authService.isAuthenticated || _authService.currentUser == null || _authService.currentUser!.uuid.isEmpty) {
      setError('User not authenticated for general profile update.');
      return;
    }

    setLoading();
    try {
      final formDataMap = {...profileData};

      if (profileImageFile != null) {
        formDataMap['profileImage'] = await dio.MultipartFile.fromFile(
          profileImageFile.path,
          filename: profileImageFile.path.split('/').last,
        );
      }
      if (coverImageFile != null) {
        formDataMap['coverImage'] = await dio.MultipartFile.fromFile(
          coverImageFile.path,
          filename: coverImageFile.path.split('/').last,
        );
      }

      final dio.FormData formData = dio.FormData.fromMap(formDataMap);

      // Assuming this is your general profile update endpoint, different from /user/onboard
      final response = await _apiService.post(
        '/api/user/profile/update/${_authService.currentUser!.uuid}', // Example general update endpoint
        data: formData,
      );

      if (response['statusCode'] == 200 && response.containsKey('data')) {
        _currentUser = User.fromJson(response['data'] as Map<String, dynamic>);
        await _authService.saveUser(_currentUser!); // Persist updated user data locally

        setSuccess();
        print('Current User Profile updated successfully for: ${_currentUser!.email}');
      } else {
        final message = response['message'] as String? ?? 'Failed to update profile: Invalid response structure.';
        setError(message);
      }
    } on dio.DioError catch (e) {
      setError(AuthService.extractErrorMessage(e));
    } catch (e) {
      setError('Failed to update profile: ${e.toString()}');
    }
  }

  Future<void> fetchUserById(String userId) async {
    setLoading();
    try {
      final response = await _apiService.get<Map<String, dynamic>>('/api/user/$userId');
      if (response['statusCode'] == 200 && response.containsKey('data')) {
        _viewedUser = User.fromJson(response['data'] as Map<String, dynamic>);
        setSuccess();
      } else {
        final message = response['message'] as String? ?? 'Failed to fetch user profile by ID: Invalid response structure.';
        setError(message);
        _viewedUser = null;
      }
    } on dio.DioError catch (e) {
      setError(AuthService.extractErrorMessage(e));
      _viewedUser = null;
    } catch (e) {
      setError('Failed to fetch user profile: ${e.toString()}');
      _viewedUser = null;
    }
  }

  // --- Pusher Integration ---
  Future<void> _subscribeToUserChannel() async {
    // Only subscribe if we have a current user and they are authenticated
    if (!_authService.isAuthenticated || _authService.currentUser == null || _authService.currentUser!.uuid.isEmpty) {
      print('Cannot subscribe to user channel: user not authenticated or UUID missing.');
      return;
    }

    final channelName = 'user.profile.${_authService.currentUser!.uuid}';
    if (_userChannelName == channelName) {
      // Already subscribed to the current user's channel, no need to re-subscribe
      return;
    }

    // Unsubscribe from previous channel if different
    if (_userChannelName != null && _userChannelName!.isNotEmpty) {
      await _pusherService.unsubscribeFromChannel(_userChannelName!);
      print('Unsubscribed from old Pusher channel: $_userChannelName');
      _userChannelName = null;
    }

    try {
      final channel = await _pusherService.subscribeToChannel(channelName);
      if (channel != null) {
        _userChannelName = channelName;
        print('Subscribed to Pusher channel: $channelName');

        _pusherService.bindToEvent(channelName, 'user.profile.updated', (eventDataString) {
          // Pusher event data often comes as a JSON string, so we need to decode it
          try {
            final Map<String, dynamic> eventData = jsonDecode(eventDataString) as Map<String, dynamic>;
            // Update local currentUser object with data from Pusher event
            // Use copyWith to ensure immutability where applicable
            _currentUser = _currentUser?.copyWith(
              firstName: eventData['firstName'] as String?,
              lastName: eventData['lastName'] as String?,
              email: eventData['email'] as String?,
              phoneNumber: eventData['phoneNumber'] as String?,
              role: eventData['role'] as String?, // Assuming 'role' can be updated via Pusher
              profileImage: eventData['profileImage'] as String?,
              coverImage: eventData['coverImage'] as String?,
              profileCompletionRate: eventData['profileCompletionRate'] as int?,
              // Update nested objects carefully, or re-parse the whole user if needed
              additionalInfo: eventData['additionalInfo'] != null && eventData['additionalInfo'] is Map
                  ? AdditionalInfo.fromJson(eventData['additionalInfo'])
                  : _currentUser?.additionalInfo,
              // ... and so on for other fields that might change via Pusher
            ) ?? User.fromJson(eventData); // Fallback to full parse if _currentUser is null

            // Important: Persist the updated user data back to local storage
            _authService.saveUser(_currentUser!);
            notifyListeners(); // Notify UI that user data has changed
            print('User profile updated via Pusher: ${_currentUser!.email}');
          } catch (e) {
            print('Error processing user.profile.updated event: ${e.toString()}. Data: $eventDataString');
          }
        });
      } else {
        print('Failed to subscribe to Pusher channel: $channelName. Channel is null.');
        _userChannelName = null;
      }
    } catch (e) {
      print('Error subscribing or binding to Pusher channel $channelName: ${e.toString()}');
      _userChannelName = null;
    }
  }

  @override
  void dispose() {
    // Unsubscribe from Pusher when provider is disposed (e.g., app closes)
    if (_userChannelName != null) {
      _pusherService.unsubscribeFromChannel(_userChannelName!);
    }
    super.dispose();
  }
}