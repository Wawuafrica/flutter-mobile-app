// import 'dart:io';
import 'package:dio/dio.dart';
// import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart'; // For kIsWeb

// Local imports
import '../services/auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio();
  
  // Base URL from environment with default value
  static final String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://staging.wawuafrica.com/api',
  );
  
  // Auth service for token management
  late final AuthService _authService;

  Future<void> initialize({
    String? apiBaseUrl,
    Map<String, String>? defaultHeaders,
    int timeoutSeconds = 30, // Reduced to reasonable timeout
    required AuthService authService,
  }) async {
    _authService = authService;
    
    // Configure timeouts based on platform
    final Duration connectTimeout = Duration(seconds: timeoutSeconds);
    final Duration receiveTimeout = Duration(seconds: timeoutSeconds);
    
    _dio.options = BaseOptions(
      baseUrl: apiBaseUrl ?? baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      // Only set sendTimeout for non-web platforms and when there's data to send
      sendTimeout: kIsWeb ? null : Duration(seconds: timeoutSeconds),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'channel': 'user',
        ...?defaultHeaders,
      },
      // Add these for better web compatibility
      validateStatus: (status) => status! < 500,
      followRedirects: true,
      maxRedirects: 3,
    );

    // Add interceptors for logging, error handling, and token refresh
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Don't set sendTimeout for GET requests or on web
          if (kIsWeb || options.method.toUpperCase() == 'GET') {
            options.sendTimeout = null;
          }
          
          print('Request: ${options.method} ${options.uri}');
          print('Headers: ${options.headers}');
          if (options.data != null && !(options.data is FormData)) {
            print('Data: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('Response: ${response.statusCode}');
          print('Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('API Error Details:');
          print('- Type: ${error.type}');
          print('- Message: ${error.message}');
          print('- Response Status: ${error.response?.statusCode}');
          print('- Request Options: ${error.requestOptions.uri}');
          
          if (error.response?.statusCode == 401) {
            print('Token expired, attempting to refresh...');
            try {
              final success = await refreshToken();
              if (success) {
                // Retry the original request with new token
                final retryOptions = error.requestOptions.copyWith(
                  headers: {
                    ...error.requestOptions.headers,
                    'Api-token': _dio.options.headers['Api-token'],
                    'channel': 'user',
                  },
                );
                
                // Clear sendTimeout for retry if on web or GET request
                if (kIsWeb || retryOptions.method.toUpperCase() == 'GET') {
                  retryOptions.sendTimeout = null;
                }
                
                final originalRequest = await _dio.fetch(retryOptions);
                return handler.resolve(originalRequest);
              }
            } catch (e) {
              print('Token refresh failed: $e');
            }
          }
          
          _handleError(error);
          return handler.next(error);
        },
      ),
    );
  }

  void setAuthToken(String token) {
    // Use Api-token header as requested
    _dio.options.headers['Api-token'] = token;
    _dio.options.headers['Authorization'] = token;
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Api-token');
    _dio.options.headers.remove('Authorization');
  }
  
  /// Refreshes the authentication token using the refresh token endpoint
  /// Returns true if token refresh was successful
  Future<bool> refreshToken() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh-token',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'channel': 'user',
          },
          sendTimeout: kIsWeb ? null : Duration(seconds: 30),
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
      print('Token refresh failed: ${e.message}');
      if (e.response?.statusCode == 401) {
        print('Refresh token expired, logging out user');
        await _authService.logout();
      }
      return false;
    } catch (e) {
      print('Unexpected error during token refresh: $e');
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
      final requestOptions = Options(
        headers: {
          'channel': 'user',
          ...?options?.headers,
        },
        sendTimeout: null, // Never set sendTimeout for GET requests
      );

      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: requestOptions,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
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
      final requestOptions = Options(
        headers: {
          'channel': 'user',
          ...?options?.headers,
        },
        sendTimeout: kIsWeb ? null : Duration(seconds: 30),
      );

      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
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
      final requestOptions = Options(
        headers: {
          'channel': 'user',
          ...?options?.headers,
        },
        sendTimeout: kIsWeb ? null : Duration(seconds: 30),
      );

      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
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
      final requestOptions = Options(
        headers: {
          'channel': 'user',
          ...?options?.headers,
        },
        sendTimeout: kIsWeb ? null : Duration(seconds: 30),
      );

      final response = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
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
      final requestOptions = Options(
        headers: {
          'channel': 'user',
          ...?options?.headers,
        },
        sendTimeout: kIsWeb ? null : Duration(seconds: 30),
      );

      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void _handleError(DioException error) {
    String message;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timed out. Please check your internet connection.';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Request send timed out. The server may be overloaded.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Response receive timed out. The server may be slow.';
        break;
      case DioExceptionType.badResponse:
        print('Bad response from server. Status code: ${error.response?.statusCode}');
        message = _handleBadResponse(error.response);
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled';
        break;
      case DioExceptionType.connectionError:
        // Enhanced error handling for connection issues
        message = _handleConnectionError(error);
        break;
      case DioExceptionType.unknown:
      default:
        message = 'An unexpected error occurred: ${error.message ?? 'Unknown error'}';
        break;
    }
    print('Error caught: $message');
  }

  String _handleConnectionError(DioException error) {
    final errorMessage = error.message?.toLowerCase() ?? '';
    
    if (errorMessage.contains('xmlhttprequest') || errorMessage.contains('network layer')) {
      if (kIsWeb) {
        return 'Network connection failed. This could be due to:\n'
               '• CORS policy blocking the request\n'
               '• Browser security settings\n'
               '• Network firewall or proxy\n'
               '• Server is unreachable\n'
               'Please check the browser console for more details.';
      } else {
        return 'Network connection error. Please check:\n'
               '• Your internet connection\n'
               '• VPN or proxy settings\n'
               '• Firewall configuration\n'
               '• Server availability';
      }
    }
    
    return 'Network connection error: ${error.message}';
  }

  String _handleBadResponse(Response? response) {
    if (response == null || response.data == null) {
      return 'No response received from server';
    }

    try {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('message')) {
          return data['message'] as String;
        } else if (data.containsKey('error')) {
          final error = data['error'];
          if (error is String) {
            return error;
          } else if (error is Map && error.containsKey('message')) {
            return error['message'] as String;
          }
        } else if (data.containsKey('errors')) {
          final errors = data['errors'];
          if (errors is Map && errors.isNotEmpty) {
            return errors.values.first.toString();
          } else if (errors is List && errors.isNotEmpty) {
            return errors.first.toString();
          }
        }
      } else if (data is String) {
        return data;
      }
      return 'Server error: ${response.statusCode}';
    } catch (e) {
      return 'Failed to parse error response. Status: ${response.statusCode}';
    }
  }
}