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
    _loadToken(); // Load token on instantiation
  }

  Future<void> _loadToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_authTokenKey);
    if (_token != null) {
      _apiService.setAuthToken(_token!);
    } else {
      _apiService.clearAuthToken();
    }
  }

  Future<void> saveToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
    _token = token;
    _apiService.setAuthToken(token);
  }

  Future<void> _clearToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    _token = null;
    _apiService.clearAuthToken();
  }

  Future<void> _saveUser(User user) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      try {
        return User.fromJson(
          jsonDecode(userDataString) as Map<String, dynamic>,
        );
      } catch (e) {
        _logger.e('Error decoding user data: $e');
        await prefs.remove(_userDataKey); // Clear corrupted data
        return null;
      }
    }
    return null;
  }

  Future<void> _clearUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
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

      if (response.containsKey('access_token') &&
          response.containsKey('user')) {
        final String token = response['access_token'] as String;
        final User user = User.fromJson(
          response['user'] as Map<String, dynamic>,
        );
        await saveToken(token);
        await _saveUser(user);
        _logger.i('Login successful for user: ${user.email}');
        return user;
      } else {
        _logger.w('Login response missing token or user data: $response');
        throw ApiException(
          response['message'] as String? ??
              'Login failed: Invalid response structure',
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
      _logger.e('Login failed (General Exception): $e');
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

      if (response.containsKey('access_token') &&
          response.containsKey('user')) {
        final String token = response['access_token'] as String;
        final User user = User.fromJson(
          response['user'] as Map<String, dynamic>,
        );
        await saveToken(token);
        await _saveUser(user);
        _logger.i('Registration successful for user: ${user.email}');
        return user;
      } else {
        _logger.w(
          'Registration response missing token or user data: $response',
        );
        throw ApiException(
          response['message'] as String? ??
              'Registration failed: Invalid response structure',
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
      _logger.e('Registration failed (General Exception): $e');
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
      await _clearToken();
      await _clearUser();
      _logger.i('Logout successful');
    } catch (e) {
      _logger.e('Error during logout: $e');
      // Still clear token and user locally even if API call fails
      await _clearToken();
      await _clearUser();
    }
  }

  Future<User> getCurrentUserProfile() async {
    try {
      _logger.i('Fetching current user profile');
      final response = await _apiService.get<Map<String, dynamic>>('/auth/me');

      if (response.containsKey('user')) {
        final User user = User.fromJson(
          response['user'] as Map<String, dynamic>,
        );
        await _saveUser(user); // Store user profile in SharedPreferences
        _logger.i('Successfully fetched user profile: ${user.email}');
        return user;
      } else {
        _logger.w('User profile response missing data: $response');
        throw ApiException(
          response['message'] as String? ?? 'Failed to fetch user profile',
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
      _logger.e('Failed to get user profile (General Exception): $e');
      throw ApiException(
        e.toString(),
        DioException(
          requestOptions: RequestOptions(path: '/api/user/profile'),
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  Future<void> sendOtp(String email, {String? type}) async {
    try {
      _logger.i('Sending OTP to email: $email for type: $type');
      final data = {'email': email};
      if (type != null) {
        data['type'] = type;
      }
      await _apiService.post('/api/user/otp/send', data: data);
      _logger.i('Send OTP request successful for email: $email');
    } on DioException catch (e) {
      _logger.e('Send OTP failed (DioException): ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Send OTP failed (General Exception): $e');
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
      _logger.i('Verifying OTP for email: $email');
      final data = {'email': email, 'otp': otp};
      if (type != null) {
        data['type'] = type;
      }
      await _apiService.post('/api/user/otp/verify', data: data);
      _logger.i('Verify OTP successful for email: $email');
    } on DioException catch (e) {
      _logger.e('Verify OTP failed (DioException): ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Verify OTP failed (General Exception): $e');
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
      _logger.i('Requesting password reset for email: $email');
      await _apiService.post('/auth/forgot-password', data: {'email': email});
      _logger.i('Forgot password request successful for email: $email');
    } on DioException catch (e) {
      _logger.e('Forgot password failed (DioException): ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Forgot password failed (General Exception): $e');
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
      _logger.i('Resetting password for email: $email');
      await _apiService.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'token': otp,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );
      _logger.i('Reset password successful for email: $email');
    } on DioException catch (e) {
      _logger.e('Reset password failed (DioException): ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Reset password failed (General Exception): $e');
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
