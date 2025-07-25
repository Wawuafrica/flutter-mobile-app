import 'dart:io';

import 'package:dio/dio.dart';
import '../services/auth_service.dart';

// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic responseData;

  ApiException(this.message, {this.statusCode, this.responseData});

  @override
  String toString() {
    return '$message (Status: $statusCode)';
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio();

  // Base URL from environment with default value
  static final String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://production.wawuafrica.com/api',
  );

  // Auth service for token management
  late final AuthService _authService;

  Future<void> initialize({
    String? apiBaseUrl,
    Map<String, String>? defaultHeaders,
    int timeoutSeconds = 60,
    required AuthService authService,
  }) async {
    _authService = authService;

    _dio.options = BaseOptions(
      baseUrl: apiBaseUrl ?? baseUrl,
      connectTimeout: Duration(seconds: timeoutSeconds),
      receiveTimeout: Duration(seconds: timeoutSeconds),
      sendTimeout: Duration(seconds: timeoutSeconds),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'channel': 'user',
        ...?defaultHeaders,
      },
      // Keep validateStatus to throw for 5xx errors, but handle them in _handleError
      validateStatus: (status) => status! < 500,
    );

    // Add interceptor for token refresh on 401 errors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            try {
              final success = await refreshToken();
              if (success) {
                // Retry the original request with new token
                final retryOptions = error.requestOptions.copyWith(
                  headers: {
                    ...error.requestOptions.headers,
                    'Authorization': _dio.options.headers['Authorization'],
                    'channel': 'user',
                  },
                );

                final originalRequest = await _dio.fetch(retryOptions);
                return handler.resolve(originalRequest);
              }
            } catch (e) {
              // Token refresh failed, let the error propagate
              // The _handleError will catch this as a DioException and rethrow ApiException
            }
          }
          // If not a 401 or refresh failed, let the error propagate to _handleError
          return handler.next(error);
        },
      ),
    );
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Refreshes the authentication token using the refresh token endpoint
  Future<bool> refreshToken() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh-token',
        options: Options(
          headers: {'Accept': 'application/json', 'channel': 'user'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        if (data.containsKey('access_token')) {
          final newToken = data['access_token'] as String;
          setAuthToken(newToken);
          await _authService.saveToken(newToken);
          return true;
        }
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _authService.logout();
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e); // This will now rethrow ApiException
      rethrow; // This rethrows the ApiException from _handleError
    }
  }

  Future<T> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e); // This will now rethrow ApiException
      rethrow; // This rethrows the ApiException from _handleError
    }
  }

  Future<T> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e); // This will now rethrow ApiException
      rethrow; // This rethrows the ApiException from _handleError
    }
  }

  Future<T> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e); // This will now rethrow ApiException
      rethrow; // This rethrows the ApiException from _handleError
    }
  }

  Future<T> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e); // This will now rethrow ApiException
      rethrow; // This rethrows the ApiException from _handleError
    }
  }

  void _handleError(DioException error) {
    String message;
    int? statusCode = error.response?.statusCode;
    dynamic responseData = error.response?.data;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message =
            'Connection timed out. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        // Extract specific error message from backend response if available
        if (responseData is Map && responseData.containsKey('message')) {
          message = responseData['message'].toString();
        } else if (responseData is String && responseData.isNotEmpty) {
          message = responseData; // Sometimes response data is a plain string
        } else {
          message = 'Server error: ${statusCode ?? 'Unknown'}';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        break;
      case DioExceptionType.connectionError:
        message =
            'Network connection error. Please check your internet connection.';
        break;
      case DioExceptionType.unknown:
      default:
        // Fallback for other unknown Dio errors or if response data is not helpful
        message = 'An unexpected error occurred. Please try again.';
        if (error.error is SocketException) {
          message = 'No internet connection. Please check your network.';
        }
        break;
    }

    // Log the error for debugging
    print('API Error: $message (Status: $statusCode, Data: $responseData)');

    // Rethrow a custom ApiException with the extracted message and status code
    throw ApiException(
      message,
      statusCode: statusCode,
      responseData: responseData,
    );
  }
}
