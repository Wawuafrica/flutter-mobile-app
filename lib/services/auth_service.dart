// lib/services/auth_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart'; // Make sure you have the logger package in pubspec.yaml

import '../models/user.dart';
import 'api_service.dart';

// Define custom exceptions for more specific error handling
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class AuthService {
  final ApiService _apiService;
  static const String _authTokenKey = 'authToken';
  static const String _userDataKey = 'userData';
  final Logger _logger = Logger(); // Initialize logger

  String? _token;
  User? _currentUser; // Internal state for the current user

  AuthService({required ApiService apiService})
      : _apiService = apiService {
    // This needs to be asynchronous, so it's often called once in main or a wrapper widget
    // _loadAuthData(); // Don't call async in constructor directly
  }

  // A getter for currentUser (this was the missing part)
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null && _currentUser!.uuid.isNotEmpty;

  // Call this method explicitly after AuthService is instantiated
  Future<void> init() async {
    await _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_authTokenKey);
      if (_token != null) {
        _apiService.setAuthToken(_token!); // Ensure ApiService also gets the token
        _logger.d('Token loaded successfully');
      } else {
        _apiService.clearAuthToken();
        _logger.d('No token found');
      }

      final userDataString = prefs.getString(_userDataKey);
      if (userDataString != null) {
        try {
          _currentUser = User.fromJson(jsonDecode(userDataString));
          _logger.d('User data loaded successfully from local storage');
        } catch (e) {
          _logger.e('Error decoding user data from local storage: $e');
          await prefs.remove(_userDataKey); // Clear corrupted data
          _currentUser = null;
        }
      } else {
        _logger.d('No user data found in local storage');
      }
    } catch (e) {
      _logger.e('Error loading auth data: $e');
    }
  }

  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authTokenKey, token);
      _token = token;
      _apiService.setAuthToken(token);
      _logger.d('Token saved successfully');
    } catch (e) {
      _logger.e('Error saving token: $e');
      throw AuthException('Failed to save authentication token.');
    }
  }

  Future<void> _clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authTokenKey);
      _token = null;
      _apiService.clearAuthToken();
      _logger.d('Token cleared successfully');
    } catch (e) {
      _logger.e('Error clearing token: $e');
    }
  }

  // Made public so UserProvider can update the locally stored user
  Future<void> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, jsonEncode(user.toJson()));
      _currentUser = user; // Update internal current user
      _logger.d('User data saved successfully to local storage and internal state');
    } catch (e) {
      _logger.e('Error saving user data: $e');
      throw AuthException('Failed to save user profile locally.');
    }
  }

  Future<void> _clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      _currentUser = null;
      _logger.d('User data cleared successfully');
    } catch (e) {
      _logger.e('Error clearing user data: $e');
    }
  }

  // Static helper to extract error message
  static String extractErrorMessage(dynamic error) {
    if (error is DioException) { // Use DioException for newer Dio versions
      if (error.response?.data != null && error.response!.data is Map) {
        final Map<String, dynamic> errorData = error.response!.data;
        if (errorData.containsKey('message') && errorData['message'] is String) {
          return errorData['message'];
        }
        if (errorData.containsKey('errors') && errorData['errors'] is Map) {
          final Map<String, dynamic> errors = errorData['errors'];
          if (errors.isNotEmpty) {
            final firstErrorKey = errors.keys.first;
            final firstErrorValue = errors[firstErrorKey];
            if (firstErrorValue is List && firstErrorValue.isNotEmpty) {
              return firstErrorValue.first.toString();
            } else if (firstErrorValue is String) {
              return firstErrorValue;
            }
          }
        }
      }
      if (error.type == DioExceptionType.badResponse) {
        return 'Server error: ${error.response?.statusCode}';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Network connection error. Please check your internet.';
      }
      return error.message ?? 'Request failed unexpectedly.';
    } else if (error is AuthException) {
      return error.message;
    }
    return 'An unexpected error occurred: ${error.toString()}';
  }

  // Renamed from 'login' to 'signIn' if more appropriate for authentication
  Future<User> signIn(String email, String password) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/user/login', // Adjust endpoint as needed
        data: {'email': email, 'password': password},
      );

      final data = response['data'];
      if (response['statusCode'] == 200 && data != null && data is Map<String, dynamic>) {
        final String token = data['token']; // Ensure token exists in response
        final user = User.fromJson(data['user']); // If user data is at root of 'data'
        // If user data is nested: final user = User.fromJson(data['user'] as Map<String, dynamic>);

        await saveToken(token);
        await saveUser(user); // Save full user object
        _logger.d('Sign-in successful for user: ${user.email}');
        return user;
      } else {
        final errorMessage = response['message'] as String? ?? 'Sign-in failed: Invalid response.';
        _logger.w(errorMessage);
        throw AuthException(errorMessage);
      }
    } catch (e) {
      final message = extractErrorMessage(e);
      _logger.e('Sign-in failed: $message');
      throw AuthException(message);
    }
  }

  Future<User> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/user/register', // Adjust endpoint as needed
        data: userData,
      );

      final data = response['data'];
      if (response['statusCode'] == 200 && data != null && data is Map<String, dynamic>) {
        final String token = data['token'];
        final user = User.fromJson(data); // If user data is at root of 'data'

        await saveToken(token);
        await saveUser(user);
        _logger.d('Registration successful for user: ${user.email}');
        return user;
      } else {
        final errorMessage = response['message'] as String? ?? 'Registration failed: Invalid response.';
        _logger.w(errorMessage);
        throw AuthException(errorMessage);
      }
    } catch (e) {
      final message = extractErrorMessage(e);
      _logger.e('Registration failed: $message');
      throw AuthException(message);
    }
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        // Assuming your backend has a logout endpoint to invalidate token
        await _apiService.post('/user/logout');
        _logger.d('Server logout successful');
      }
    } catch (e) {
      _logger.e('Server logout failed (might be network issue or token invalidation): $e');
    } finally {
      await _clearToken();
      await _clearUser();
      _logger.d('Local logout complete');
    }
  }

  Future<User> getCurrentUserProfile() async {
    try {
      if (!isAuthenticated  || _currentUser == null || _currentUser!.uuid.isEmpty) {
        throw AuthException('Not authenticated. No token or user found.');
      }


      final userId = _currentUser!.uuid; // <-- EXTRACING THE USER'S UUID HERE
      print('AuthService: Attempting to fetch user profile for UUID: $userId');
      
      final response = await _apiService.get<Map<String, dynamic>>('/user/$userId'); // Or /user/profile
      // Assuming 'data' key contains the user object, or the response itself is the user object
      final userMap = response['data'] ?? response;
      print('THIS IS THE user data $userMap');
      if (response['statusCode'] == 200 && userMap != null && userMap is Map<String, dynamic>) {
        final user = User.fromJson(userMap);
        await saveUser(user); // Update local storage with fresh profile data
        _logger.d('User profile fetched successfully');
        return user;
      } else {
        final errorMessage = response['message'] as String? ?? 'Failed to fetch user profile: Invalid response structure.';
        _logger.w(errorMessage);
        throw AuthException(errorMessage);
      }
    } catch (e) {
      final message = extractErrorMessage(e);
      _logger.e('Failed to get user profile: $message');
      // await logout(); // Invalidate local session if profile cannot be fetched (e.g., token expired)
      throw AuthException(message);
    }
  }

  // Keeping these here as they are part of typical auth flows
  Future<void> sendOtp(String email, {String? type}) async {
    try {
      final data = {'email': email};
      if (type != null) data['type'] = type;
      await _apiService.post('/api/user/otp/send', data: data);
      _logger.d('OTP sent successfully for email: $email');
    } catch (e) {
      final message = extractErrorMessage(e);
      _logger.e('Send OTP failed: $message');
      throw AuthException(message);
    }
  }

  Future<void> verifyOtp(String email, String otp, {String? type}) async {
    try {
      final data = {'email': email, 'otp': otp};
      if (type != null) data['type'] = type;
      await _apiService.post('/api/user/otp/verify', data: data);
      _logger.d('OTP verified successfully for email: $email');
    } catch (e) {
      final message = extractErrorMessage(e);
      _logger.e('Verify OTP failed: $message');
      throw AuthException(message);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _apiService.post('/auth/forgot-password', data: {'email': email});
      _logger.d('Forgot password request sent successfully for email: $email');
    } catch (e) {
      final message = extractErrorMessage(e);
      _logger.e('Forgot password failed: $message');
      throw AuthException(message);
    }
  }

  Future<void> resetPassword(
    String email,
    String otp,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      await _apiService.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'token': otp, // Backend might expect 'token' instead of 'otp' for reset
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );
      _logger.d('Password reset successfully for email: $email');
    } catch (e) {
      final message = extractErrorMessage(e);
      _logger.e('Reset password failed: $message');
      throw AuthException(message);
    }
  }
}