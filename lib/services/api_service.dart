import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

// Local imports
import '../services/auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio();
  final Logger _logger = Logger();
  
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
    int timeoutSeconds = 30,
    required AuthService authService,
  }) async {
    _authService = authService;
    
    _dio.options = BaseOptions(
      baseUrl: apiBaseUrl ?? baseUrl,
      connectTimeout: Duration(seconds: timeoutSeconds),
      receiveTimeout: Duration(seconds: timeoutSeconds),
      headers: defaultHeaders,
    );

    // Add interceptors for logging, error handling, and token refresh
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.i('Request: ${options.method} ${options.uri}');
          _logger.i('Headers: ${options.headers}');
          if (options.data != null && !(options.data is FormData)) {
            _logger.i('Data: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i('Response: ${response.statusCode}');
          _logger.d('Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            _logger.w('Token expired, attempting to refresh...');
            try {
              final success = await refreshToken();
              if (success) {
                // Retry the original request with new token
                final opts = Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                );
                final originalRequest = await _dio.request<dynamic>(
                  error.requestOptions.path,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                  options: opts,
                );
                return handler.resolve(originalRequest);
              }
            } catch (e) {
              _logger.e('Token refresh failed: $e');
            }
          }
          _logger.e('API Error: ${error.message}');
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
  /// Returns true if token refresh was successful
  Future<bool> refreshToken() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh-token',
        options: Options(headers: {
          'Accept': 'application/json',
        }),
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
      _logger.e('Token refresh failed: ${e.message}');
      // If refresh token is invalid, log the user out
      if (e.response?.statusCode == 401) {
        _logger.w('Refresh token expired, logging out user');
        await _authService.logout();
      }
      return false;
    } catch (e) {
      _logger.e('Unexpected error during token refresh: $e');
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
      _handleError(e);
      rethrow;
    }
  }
  
  /// Uploads a file along with form data to the specified endpoint
  /// 
  /// [endpoint] - API endpoint to upload to
  /// [file] - File to upload
  /// [field] - Form field name for the file
  /// [formData] - Additional form data to include
  /// [onSendProgress] - Optional callback for upload progress
  Future<T> uploadFile<T>(
    String endpoint, {
    required File file,
    required String field,
    Map<String, dynamic>? formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      // Create form data
      final fileName = path.basename(file.path);
      final formDataObj = FormData();
      
      // Add file
      formDataObj.files.add(MapEntry(
        field,
        await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      ));
      
      // Add other fields
      if (formData != null) {
        formData.forEach((key, value) {
          formDataObj.fields.add(MapEntry(key, value.toString()));
        });
      }
      
      final response = await _dio.post(
        endpoint,
        data: formDataObj,
        queryParameters: queryParameters,
        options: options,
        onSendProgress: onSendProgress,
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
  
  /// Uploads multiple files along with form data to the specified endpoint
  /// 
  /// [endpoint] - API endpoint to upload to
  /// [files] - Map of field names to files
  /// [formData] - Additional form data to include
  /// [onSendProgress] - Optional callback for upload progress
  Future<T> uploadMultipleFiles<T>(
    String endpoint, {
    required Map<String, File> files,
    Map<String, dynamic>? formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      // Create form data
      final formDataObj = FormData();
      
      // Add files
      for (final entry in files.entries) {
        final fileName = path.basename(entry.value.path);
        formDataObj.files.add(MapEntry(
          entry.key,
          await MultipartFile.fromFile(
            entry.value.path,
            filename: fileName,
          ),
        ));
      }
      
      // Add other fields
      if (formData != null) {
        formData.forEach((key, value) {
          formDataObj.fields.add(MapEntry(key, value.toString()));
        });
      }
      
      final response = await _dio.post(
        endpoint,
        data: formDataObj,
        queryParameters: queryParameters,
        options: options,
        onSendProgress: onSendProgress,
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

  Never _handleError(DioException error) {
    String message;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        message = _handleBadResponse(error.response);
        // Handle specific status codes
        if (error.response?.statusCode == 403) {
          message = 'You don\'t have permission to access this resource';
        } else if (error.response?.statusCode == 404) {
          message = 'The requested resource was not found';
        } else if (error.response?.statusCode == 500) {
          message = 'Server error. Please try again later';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please check your network settings.';
        break;
      default:
        message = 'An unexpected error occurred';
    }
    throw ApiException(message, error);
  }

  String _handleBadResponse(Response? response) {
    if (response == null) return 'No response received';

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
      }
      return 'Server error: ${response.statusCode}';
    } catch (e) {
      return 'Server error: ${response.statusCode}';
    }
  }
}

class ApiException implements Exception {
  final String message;
  final DioException originalError;
  final int? statusCode;

  ApiException(this.message, this.originalError)
      : statusCode = originalError.response?.statusCode;

  @override
  String toString() => message;
}
