// lib/services/auth_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import '../models/user.dart';
import 'api_service.dart';

// Removed custom AuthException class as per architectural guidelines.
// Providers should catch generic Exception and use the message from ApiService.

class AuthService {
  final ApiService _apiService;
  static const String _authTokenKey = 'authToken';
  static const String _userDataKey = 'userData';
  final Logger _logger = Logger();

  String? _token;
  User? _currentUser; // Internal state for the current user

  AuthService({required ApiService apiService}) : _apiService = apiService {
    // This needs to be asynchronous, so it's often called once in main or a wrapper widget
    // _loadAuthData(); // Don't call async in constructor directly
  }

  // A getter for currentUser (this was the missing part)
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated =>
      _token != null && _currentUser != null && _currentUser!.uuid.isNotEmpty;

  // Call this method explicitly after AuthService is instantiated
  Future<void> init() async {
    await _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_authTokenKey);
      if (_token != null) {
        _apiService.setAuthToken(
          _token!,
        ); // Ensure ApiService also gets the token
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
      // No rethrow here as this is internal loading, not an API call.
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
      // Rethrow as generic Exception, ApiService handles DioException.
      throw Exception('Failed to save authentication token: ${e.toString()}');
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
      // No rethrow here as this is internal cleanup.
    }
  }

  // Made public so UserProvider can update the locally stored user
  Future<void> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, jsonEncode(user.toJson()));
      _currentUser = user; // Update internal current user
      _logger.d(
        'User data saved successfully to local storage and internal state',
      );
    } catch (e) {
      _logger.e('Error saving user data: $e');
      // Rethrow as generic Exception.
      throw Exception('Failed to save user profile locally: ${e.toString()}');
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
      // No rethrow here as this is internal cleanup.
    }
  }

  // Removed extractErrorMessage method as per architectural guidelines.

  // Renamed from 'login' to 'signIn' if more appropriate for authentication
  Future<User> signIn(String email, String password) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/user/login', // Adjust endpoint as needed
        data: {'email': email, 'password': password},
      );

      final data = response['data'];
      if (response['statusCode'] == 200 &&
          data != null &&
          data is Map<String, dynamic>) {
        final String token = data['token']; // Ensure token exists in response
        final user = User.fromJson(
          data['user'],
        ); // If user data is at root of 'data'
        // If user data is nested: final user = User.fromJson(data['user'] as Map<String, dynamic>);

        await saveToken(token);
        await saveUser(user); // Save full user object
        _logger.d('Sign-in successful for user: ${user.email}');
        return user;
      } else {
        final errorMessage =
            response['message'] as String? ??
            'Sign-in failed: Invalid response.';
        _logger.w(errorMessage);
        // Throw generic Exception, ApiService has already handled DioException.
        throw Exception(errorMessage);
      }
    } catch (e) {
      _logger.e('Sign-in failed: $e');
      rethrow; // Rethrow the exception with the message from ApiService
    }
  }

  Future<User> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/user/register', // Adjust endpoint as needed
        data: userData,
      );

      final data = response['data'];
      if (response['statusCode'] == 200 &&
          data != null &&
          data is Map<String, dynamic>) {
        final String token = data['token'];
        final user = User.fromJson(data); // If user data is at root of 'data'

        await saveToken(token);
        await saveUser(user);
        _logger.d('Registration successful for user: ${user.email}');
        return user;
      } else {
        final errorMessage =
            response['message'] as String? ??
            'Registration failed: Invalid response.';
        _logger.w(errorMessage);
        // Throw generic Exception, ApiService has already handled DioException.
        throw Exception(errorMessage);
      }
    } catch (e) {
      _logger.e('Registration failed: $e');
      rethrow; // Rethrow the exception with the message from ApiService
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
      _logger.e(
        'Server logout failed (might be network issue or token invalidation): $e',
      );
      // No rethrow here, as logout should attempt to clear local data regardless of server response.
    } finally {
      await _clearToken();
      await _clearUser();
      _logger.d('Local logout complete');
    }
  }

  Future<User> getCurrentUserProfile() async {
    try {
      if (!isAuthenticated ||
          _currentUser == null ||
          _currentUser!.uuid.isEmpty) {
        throw Exception(
          'Not authenticated. No token or user found.',
        ); // Throw generic Exception
      }

      final userId = _currentUser!.uuid; // <-- EXTRACING THE USER'S UUID HERE
      print('AuthService: Attempting to fetch user profile for UUID: $userId');

      final response = await _apiService.get<Map<String, dynamic>>(
        '/user/$userId',
      ); // Or /user/profile
      // Assuming 'data' key contains the user object, or the response itself is the user object
      final userMap = response['data'] ?? response;
      print('THIS IS THE user data $userMap');
      if (response['statusCode'] == 200 &&
          userMap != null &&
          userMap is Map<String, dynamic>) {
        final user = User.fromJson(userMap);
        await saveUser(user); // Update local storage with fresh profile data
        _logger.d('User profile fetched successfully');
        return user;
      } else {
        final errorMessage =
            response['message'] as String? ??
            'Failed to fetch user profile: Invalid response structure.';
        _logger.w(errorMessage);
        // Throw generic Exception, ApiService has already handled DioException.
        throw Exception(errorMessage);
      }
    } catch (e) {
      _logger.e('Failed to get user profile: $e');
      // await logout(); // Invalidate local session if profile cannot be fetched (e.g., token expired)
      rethrow; // Rethrow the exception with the message from ApiService
    }
  }

  // Keeping these here as they are part of typical auth flows
  Future<void> sendOtp(String email, {String? type}) async {
    try {
      final data = {'email': email};
      if (type != null) data['type'] = type;
      await _apiService.post('/user/otp/send', data: data);
      _logger.d('OTP sent successfully for email: $email');
    } catch (e) {
      _logger.e('Send OTP failed: $e');
      rethrow; // Rethrow the exception with the message from ApiService
    }
  }

  Future<void> verifyOtp(String email, String otp, {String? type}) async {
    try {
      final data = {'email': email, 'otp': otp};
      if (type != null) data['type'] = type;
      await _apiService.post('/user/otp/verify', data: data);
      _logger.d('OTP verified successfully for email: $email');
    } catch (e) {
      _logger.e('Verify OTP failed: $e');
      rethrow; // Rethrow the exception with the message from ApiService
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _apiService.post('/user/password/forgot', data: {'email': email});
      _logger.d('Forgot password request sent successfully for email: $email');
    } catch (e) {
      _logger.e('Forgot password failed: $e');
      rethrow; // Rethrow the exception with the message from ApiService
    }
  }

  Future<void> resetPassword(
    String email,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      await _apiService.post(
        '/user/password/reset',
        data: {
          'email': email,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );
      _logger.d('Password reset successfully for email: $email');
    } catch (e) {
      _logger.e('Reset password failed: $e');
      rethrow; // Rethrow the exception with the message from ApiService
    }
  }
}
