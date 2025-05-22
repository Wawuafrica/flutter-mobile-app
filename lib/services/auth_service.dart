import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;
  final Logger _logger;
  static const String _authTokenKey = 'authToken';
  static const String _userDataKey = 'userData';

  String? _token;

  AuthService({required ApiService apiService, required Logger logger})
      : _apiService = apiService,
        _logger = logger {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_authTokenKey);
    if (_token != null) {
      _apiService.setAuthToken(_token!);
    } else {
      _apiService.clearAuthToken();
    }
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
    _token = token;
    _apiService.setAuthToken(token);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    _token = null;
    _apiService.clearAuthToken();
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      try {
        return User.fromJson(jsonDecode(userDataString));
      } catch (e) {
        _logger.e('Error decoding user data: $e');
        await prefs.remove(_userDataKey);
        return null;
      }
    }
    return null;
  }

  Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Future<User> login(String email, String password) async {
    try {
      _logger.i('Attempting login for email: $email');
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
        _logger.i('Login successful for user: ${user.email}');
        return user;
      } else {
        throw ApiException(
          response['message'] ?? 'Login failed: Invalid response structure',
          DioException(
            requestOptions: RequestOptions(path: '/user/login'),
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on DioException catch (e) {
      _logger.e('Login failed (DioException): ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Login failed (Exception): $e');
      throw ApiException(
        e.toString(),
        DioException(
          requestOptions: RequestOptions(path: '/user/login'),
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  Future<User> register(Map<String, dynamic> userData) async {
    try {
      _logger.i('Attempting registration with data: $userData');
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
        _logger.i('Registration successful for user: ${user.email}');
        return user;
      } else {
        throw ApiException(
          response['message'] ?? 'Registration failed: Invalid response structure',
          DioException(
            requestOptions: RequestOptions(path: '/user/register'),
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on DioException catch (e) {
      _logger.e('Registration failed (DioException): ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Registration failed (Exception): $e');
      throw ApiException(
        e.toString(),
        DioException(
          requestOptions: RequestOptions(path: '/user/register'),
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  Future<void> logout() async {
    try {
      _logger.i('Logging out user');
      await _apiService.post('/auth/logout');
    } catch (e) {
      _logger.e('Logout failed: $e');
    } finally {
      await _clearToken();
      await _clearUser();
      _logger.i('Local logout complete');
    }
  }

  Future<User> getCurrentUserProfile() async {
    try {
      _logger.i('Fetching current user profile');
      final response = await _apiService.get<Map<String, dynamic>>('/auth/me');

      final userMap = response['user'];
      if (userMap != null && userMap is Map<String, dynamic>) {
        final user = User.fromJson(userMap);
        await _saveUser(user);
        return user;
      } else {
        throw ApiException(
          response['message'] ?? 'Failed to fetch user profile',
          DioException(
            requestOptions: RequestOptions(path: '/auth/me'),
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on DioException catch (e) {
      _logger.e('Failed to get user profile (DioException): ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Failed to get user profile (Exception): $e');
      throw ApiException(
        e.toString(),
        DioException(
          requestOptions: RequestOptions(path: '/auth/me'),
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  Future<void> sendOtp(String email, {String? type}) async {
    try {
      final data = {'email': email};
      if (type != null) data['type'] = type;
      await _apiService.post('/api/user/otp/send', data: data);
    } on DioException catch (e) {
      _logger.e('Send OTP failed (DioException): ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Send OTP failed (Exception): $e');
      throw ApiException(
        e.toString(),
        DioException(
          requestOptions: RequestOptions(path: '/api/user/otp/send'),
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  Future<void> verifyOtp(String email, String otp, {String? type}) async {
    try {
      final data = {'email': email, 'otp': otp};
      if (type != null) data['type'] = type;
      await _apiService.post('/api/user/otp/verify', data: data);
    } on DioException catch (e) {
      _logger.e('Verify OTP failed (DioException): ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Verify OTP failed (Exception): $e');
      throw ApiException(
        e.toString(),
        DioException(
          requestOptions: RequestOptions(path: '/api/user/otp/verify'),
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _apiService.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      _logger.e('Forgot password failed (DioException): ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Forgot password failed (Exception): $e');
      throw ApiException(
        e.toString(),
        DioException(
          requestOptions: RequestOptions(path: '/auth/forgot-password'),
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
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
    } on DioException catch (e) {
      _logger.e('Reset password failed (DioException): ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Reset password failed (Exception): $e');
      throw ApiException(
        e.toString(),
        DioException(
          requestOptions: RequestOptions(path: '/auth/reset-password'),
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
