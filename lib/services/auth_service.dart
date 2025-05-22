import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart'; // Assuming logger package is installed

import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;
  static const String _authTokenKey = 'authToken';
  static const String _userDataKey = 'userData';
  final Logger _logger = Logger(); // Initialize logger

  String? _token;

  AuthService({required ApiService apiService})
      : _apiService = apiService {
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_authTokenKey);
      if (_token != null) {
        _apiService.setAuthToken(_token!);
        _logger.d('Token loaded successfully');
      } else {
        _apiService.clearAuthToken();
        _logger.d('No token found');
      }
    } catch (e) {
      _logger.e('Error loading token: $e');
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

  Future<void> _saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, jsonEncode(user.toJson()));
      _logger.d('User data saved successfully');
    } catch (e) {
      _logger.e('Error saving user data: $e');
    }
  }

  Future<User?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      if (userDataString != null) {
        try {
          final user = User.fromJson(jsonDecode(userDataString));
          _logger.d('User data retrieved successfully');
          return user;
        } catch (e) {
          _logger.e('Error decoding user data: $e');
          await prefs.remove(_userDataKey);
          return null;
        }
      }
      _logger.d('No user data found');
      return null;
    } catch (e) {
      _logger.e('Error retrieving user data: $e');
      return null;
    }
  }

  Future<void> _clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      _logger.d('User data cleared successfully');
    } catch (e) {
      _logger.e('Error clearing user data: $e');
    }
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Future<User> login(String email, String password) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/user/login',
        data: {'email': email, 'password': password},
      );

      final data = response['data'];
      if (data != null && data is Map<String, dynamic>) {
        final String token = data['token'];
        final user = User.fromJson(data);
        await saveToken(token);
        await _saveUser(user);
        _logger.d('Login successful for user: ${user.email}');
        return user;
      } else {
        _logger.w(response['message'] ?? 'Login failed: Invalid response structure');
        return User.fromJson(response);
      }
    } catch (e) {
      _logger.e('Login failed: $e');
      return User.fromJson({});
    }
  }

  Future<User> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/user/register',
        data: userData,
      );

      final data = response['data'];
      if (data != null && data is Map<String, dynamic>) {
        final String token = data['token'];
        final user = User.fromJson(data);
        await saveToken(token);
        await _saveUser(user);
        _logger.d('Registration successful for user: ${user.email}');
        return user;
      } else {
        _logger.w(response['message'] ?? 'Registration failed: Invalid response structure');
        return User.fromJson({});
      }
    } catch (e) {
      _logger.e('Registration failed: $e');
      return User.fromJson({});
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.post('/auth/logout');
      _logger.d('Server logout successful');
    } catch (e) {
      _logger.e('Logout failed: $e');
    } finally {
      await _clearToken();
      await _clearUser();
      _logger.d('Local logout complete');
    }
  }

  Future<User> getCurrentUserProfile() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>('/auth/me');

      final userMap = response['user'];
      if (userMap != null && userMap is Map<String, dynamic>) {
        final user = User.fromJson(userMap);
        await _saveUser(user);
        _logger.d('User profile fetched successfully');
        return user;
      } else {
        _logger.w(response['message'] ?? 'Failed to fetch user profile');
        return User.fromJson({});
      }
    } catch (e) {
      _logger.e('Failed to get user profile: $e');
      return User.fromJson({});
    }
  }

  Future<void> sendOtp(String email, {String? type}) async {
    try {
      final data = {'email': email};
      if (type != null) data['type'] = type;
      await _apiService.post('/api/user/otp/send', data: data);
      _logger.d('OTP sent successfully for email: $email');
    } catch (e) {
      _logger.e('Send OTP failed: $e');
    }
  }

  Future<void> verifyOtp(String email, String otp, {String? type}) async {
    try {
      final data = {'email': email, 'otp': otp};
      if (type != null) data['type'] = type;
      await _apiService.post('/api/user/otp/verify', data: data);
      _logger.d('OTP verified successfully for email: $email');
    } catch (e) {
      _logger.e('Verify OTP failed: $e');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _apiService.post('/auth/forgot-password', data: {'email': email});
      _logger.d('Forgot password request sent successfully for email: $email');
    } catch (e) {
      _logger.e('Forgot password failed: $e');
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
          'token': otp,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );
      _logger.d('Password reset successfully for email: $email');
    } catch (e) {
      _logger.e('Reset password failed: $e');
    }
  }
}