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
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
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
    // Return user-friendly error messages based on status codes
    if (e.type == DioExceptionType.connectionTimeout || 
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timed out. Please check your internet.');
    }
    
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      if (statusCode == 401) {
        return Exception('Unauthorized. Please sign in again.');
      } else if (statusCode == 403) {
        return Exception('Access denied.');
      } if (statusCode == 404) {
        return Exception('Resource not found.');
      } else if (statusCode! >= 500) {
        return Exception('Server error. Please try again later.');
      }
      
      // Try to extract server message
      final data = e.response!.data;
      if (data is Map && data.containsKey('detail')) {
        return Exception(data['detail']);
      }
    }
    
    return Exception('Something went wrong. Please try again.');
  }
}
