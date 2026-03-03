import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';
import '../repositories/auth_repository.dart';

/// Service for making API calls with Dio
class ApiService {
  final AuthRepository _authRepository;
  late final Dio _dio;
  
  ApiService({required AuthRepository authRepository}) : _authRepository = authRepository {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if user is signed in
          try {
            if (_authRepository.isAuthenticated) {
              final token = await _authRepository.getIdToken();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            }
          } catch (e) {
            AppLogger.error('Failed to get auth token', tag: 'ApiService', error: e);
          }
          
          print('[API] Full URL: ${options.uri}');
          print('[API] Request: ${options.method} ${options.path}');
          print('[API] Data: ${options.data}');
          AppLogger.info('Request: ${options.method} ${options.path}', tag: 'ApiService');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.success(
            'Response: ${response.statusCode} ${response.requestOptions.path}',
            tag: 'ApiService',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          AppLogger.error(
            'Error: ${e.message}',
            tag: 'ApiService',
            error: e.error,
          );
          return handler.next(e);
        },
      ),
    );
  }
  
  // GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    print('[API POST] Starting post to: $path');
    print('[API POST] Base URL: ${_dio.options.baseUrl}');
    print('[API POST] Full URL: ${_dio.options.baseUrl}$path');
    print('[API POST] Data: $data');
    try {
      print('[API POST] Calling dio.post...');
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      print('[API POST] Response received: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('[API POST] DioException: ${e.type} - ${e.message}');
      print('[API POST] DioException response: ${e.response?.data}');
      throw _handleDioError(e);
    } catch (e) {
      print('[API POST] Unknown exception: $e');
      rethrow;
    }
  }
  
  // PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Exception _handleDioError(DioException e) {
    // Log full error details
    AppLogger.error(
      'DioError: type=${e.type}, status=${e.response?.statusCode}, data=${e.response?.data}',
      tag: 'ApiService',
      error: e,
    );
    
    // Return user-friendly error messages based on status codes
    if (e.type == DioExceptionType.connectionTimeout || 
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timed out. Please check your internet.');
    }
    
    if (e.type == DioExceptionType.connectionError) {
      return Exception('Connection error. Is the backend server running?');
    }
    
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      
      if (statusCode == 401) {
        return Exception('Unauthorized. Please sign in again.');
      } else if (statusCode == 403) {
        return Exception('Access denied.');
      } else if (statusCode == 404) {
        return Exception('Resource not found.');
      } else if (statusCode == 422) {
        // Validation error - extract detailed message
        if (data is Map && data.containsKey('detail')) {
          final detail = data['detail'];
          if (detail is List && detail.isNotEmpty) {
            // Pydantic validation errors are in list format
            final errors = detail.map((e) => '${e['loc']?.join('.')}: ${e['msg']}').join(', ');
            return Exception('Validation error: $errors');
          }
          return Exception('Validation error: $detail');
        }
        return Exception('Invalid request data.');
      } else if (statusCode! >= 500) {
        return Exception('Server error. Please try again later.');
      }
      
      // Try to extract server message
      if (data is Map && data.containsKey('detail')) {
        return Exception(data['detail'].toString());
      }
    }
    
    return Exception('Something went wrong. Please try again.');
  }
}
