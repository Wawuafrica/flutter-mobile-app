// lib/services/auth_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;
  static const String _authTokenKey = 'authToken';
  static const String _userDataKey = 'userData';
  static const String _userDataBackupKey = 'userData_backup'; // Backup key
  final Logger _logger = Logger();

  String? _token;
  User? _currentUser;

  AuthService({required ApiService apiService}) : _apiService = apiService;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated =>
      _token != null && _currentUser != null && _currentUser!.uuid.isNotEmpty;

  Future<void> init() async {
    await _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load token
      _token = prefs.getString(_authTokenKey);
      if (_token != null) {
        _apiService.setAuthToken(_token!);
        _logger.d('Token loaded successfully');
      } else {
        _apiService.clearAuthToken();
        _logger.d('No token found');
      }

      // Load user data with better error handling
      await _loadUserData(prefs);
    } catch (e) {
      _logger.e('Critical error loading auth data: $e');
      // Don't clear data on critical errors, just log them
    }
  }

  Future<void> _loadUserData(SharedPreferences prefs) async {
    final userDataString = prefs.getString(_userDataKey);

    if (userDataString == null) {
      _logger.d('No user data found in local storage');
      return;
    }

    // First, try to parse the current user data
    try {
      final userJson = jsonDecode(userDataString) as Map<String, dynamic>;
      _currentUser = User.fromJson(userJson);
      _logger.d('User data loaded successfully from local storage');

      // Create backup of successfully parsed data
      await prefs.setString(_userDataBackupKey, userDataString);
      return;
    } catch (parseError) {
      _logger.e('Error decoding current user data: $parseError');

      // Try to load from backup
      final backupUserDataString = prefs.getString(_userDataBackupKey);
      if (backupUserDataString != null) {
        try {
          final backupUserJson =
              jsonDecode(backupUserDataString) as Map<String, dynamic>;
          _currentUser = User.fromJson(backupUserJson);
          _logger.i('User data restored from backup');

          // Restore the backup as current data
          await prefs.setString(_userDataKey, backupUserDataString);
          return;
        } catch (backupError) {
          _logger.e('Error decoding backup user data: $backupError');
        }
      }

      // Only delete corrupted data if we've tried everything
      _logger.w(
        'Corrupted user data detected. Clearing only after backup attempts failed.',
      );
      await prefs.remove(_userDataKey);
      await prefs.remove(_userDataBackupKey);
      _currentUser = null;
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
    }
  }

  // Enhanced saveUser with backup mechanism
  Future<void> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonString = jsonEncode(user.toJson());

      // Validate the JSON by trying to parse it back
      try {
        final testJson = jsonDecode(userJsonString) as Map<String, dynamic>;
        User.fromJson(testJson); // This will throw if the data is invalid
      } catch (validationError) {
        _logger.e(
          'User data validation failed before saving: $validationError',
        );
        throw Exception(
          'Invalid user data structure: ${validationError.toString()}',
        );
      }

      // Create backup of existing data before overwriting
      final existingData = prefs.getString(_userDataKey);
      if (existingData != null) {
        await prefs.setString(_userDataBackupKey, existingData);
      }

      // Save new data
      await prefs.setString(_userDataKey, userJsonString);
      _currentUser = user;
      _logger.d(
        'User data saved successfully to local storage and internal state',
      );
    } catch (e) {
      _logger.e('Error saving user data: $e');
      throw Exception('Failed to save user profile locally: ${e.toString()}');
    }
  }

  Future<void> _clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      await prefs.remove(_userDataBackupKey);
      _currentUser = null;
      _logger.d('User data cleared successfully');
    } catch (e) {
      _logger.e('Error clearing user data: $e');
    }
  }

  // Add a method to manually recover user data
  Future<bool> attemptUserDataRecovery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _loadUserData(prefs);
      return _currentUser != null;
    } catch (e) {
      _logger.e('User data recovery failed: $e');
      return false;
    }
  }

  // Add debugging method to inspect stored data
  Future<Map<String, dynamic>> debugStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'hasToken': prefs.getString(_authTokenKey) != null,
        'hasUserData': prefs.getString(_userDataKey) != null,
        'hasBackupData': prefs.getString(_userDataBackupKey) != null,
        'userDataRaw': prefs.getString(_userDataKey),
        'tokenRaw': prefs.getString(_authTokenKey),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<User> signIn(String email, String password) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/user/login',
        data: {'email': email, 'password': password},
      );

      final data = response['data'];
      if (response['statusCode'] == 200 &&
          data != null &&
          data is Map<String, dynamic>) {
        final String token = data['token'];
        final user = User.fromJson(data['user']);

        await saveToken(token);
        await saveUser(user);
        _logger.d('Sign-in successful for user: ${user.email}');
        return user;
      } else {
        final errorMessage =
            response['message'] as String? ??
            'Sign-in failed: Invalid response.';
        _logger.w(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      _logger.e('Sign-in failed: $e');
      rethrow;
    }
  }

  Future<User> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/user/register',
        data: userData,
      );

      final data = response['data'];
      if (response['statusCode'] == 200 &&
          data != null &&
          data is Map<String, dynamic>) {
        final String token = data['token'];
        final user = User.fromJson(data);

        await saveToken(token);
        await saveUser(user);
        _logger.d('Registration successful for user: ${user.email}');
        return user;
      } else {
        final errorMessage =
            response['message'] as String? ??
            'Registration failed: Invalid response.';
        _logger.w(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      _logger.e('Registration failed: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await _apiService.post('/user/logout');
        _logger.d('Server logout successful');
      }
    } catch (e) {
      _logger.e(
        'Server logout failed (might be network issue or token invalidation): $e',
      );
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
        throw Exception('Not authenticated. No token or user found.');
      }

      final userId = _currentUser!.uuid;
      _logger.d(
        'AuthService: Attempting to fetch user profile for UUID: $userId',
      );

      final response = await _apiService.get<Map<String, dynamic>>(
        '/user/$userId',
      );
      final userMap = response['data'] ?? response;

      _logger.d('AuthService: Received user data: $userMap');

      if (response['statusCode'] == 200 &&
          userMap != null &&
          userMap is Map<String, dynamic>) {
        final user = User.fromJson(userMap);
        await saveUser(user);
        _logger.d('User profile fetched and saved successfully');
        return user;
      } else {
        final errorMessage =
            response['message'] as String? ??
            'Failed to fetch user profile: Invalid response structure.';
        _logger.w(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      _logger.e('Failed to get user profile: $e');
      rethrow;
    }
  }

  Future<void> sendOtp(String email, {String? type}) async {
    try {
      final data = {'email': email};
      if (type != null) data['type'] = type;
      await _apiService.post('/user/otp/send', data: data);
      _logger.d('OTP sent successfully for email: $email');
    } catch (e) {
      _logger.e('Send OTP failed: $e');
      rethrow;
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
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _apiService.post('/user/password/forgot', data: {'email': email});
      _logger.d('Forgot password request sent successfully for email: $email');
    } catch (e) {
      _logger.e('Forgot password failed: $e');
      rethrow;
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
      rethrow;
    }
  }
}
