import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../utils/constants.dart';
import 'api_interceptor.dart';

/// HTTP client for API calls
class ApiClient {
  late final Dio _dio;
  final SecureStorageService _storage;

  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          ApiConstants.headerContentType: ApiConstants.contentTypeJson,
        },
      ),
    );

    // Add interceptor
    _dio.interceptors.add(ApiInterceptor(_storage));
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle API errors
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet.');
      
      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);
      
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      
      case DioExceptionType.connectionError:
        return Exception('No internet connection');
      
      default:
        return Exception('Something went wrong. Please try again.');
    }
  }

  /// Handle HTTP response errors
  Exception _handleResponseError(Response? response) {
    if (response == null) {
      return Exception('No response from server');
    }

    final statusCode = response.statusCode;
    final data = response.data;

    // Try to extract error message from response
    String message = 'Something went wrong';
    if (data is Map<String, dynamic> && data.containsKey('error')) {
      message = data['error'].toString();
    }

    switch (statusCode) {
      case 400:
        return Exception(message);
      case 401:
        return Exception('Unauthorized. Please login again.');
      case 403:
        return Exception('Access forbidden');
      case 404:
        return Exception('Resource not found');
      case 500:
        return Exception('Server error. Please try again later.');
      default:
        return Exception(message);
    }
  }
}
