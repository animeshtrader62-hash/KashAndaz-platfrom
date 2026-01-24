import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../utils/constants.dart';
import 'api_interceptor.dart';
import 'api_exceptions.dart';

/// HTTP client for API calls
class ApiClient {
  late final Dio _dio;
  final SecureStorageService _storage;

  ApiClient(this._storage) {
    // Helpful for debugging device/emulator/web base URL issues.
    // Remove later if you don't want this log.
    // ignore: avoid_print
    print('[ApiClient] baseUrl=${ApiConstants.baseUrl}');

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
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
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
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
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
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
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
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
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
        return ApiTimeoutException('Connection timeout. Please check your internet.');
      
      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);
      
      case DioExceptionType.cancel:
        return ApiCancelledException('Request cancelled');
      
      case DioExceptionType.connectionError:
        return ApiNetworkException('No internet connection');
      
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

    // Try to extract a useful error message from common backend shapes.
    // FastAPI typically returns:
    // - {"detail": "..."}
    // - {"detail": [{"msg": "...", ...}, ...]} for 422
    String message = 'Something went wrong';
    if (data is Map<String, dynamic>) {
      if (data['detail'] is String) {
        message = (data['detail'] as String).trim();
      } else if (data['detail'] is List) {
        final detailList = data['detail'] as List;
        if (detailList.isNotEmpty && detailList.first is Map) {
          final first = detailList.first as Map;
          final msg = first['msg']?.toString();
          if (msg != null && msg.trim().isNotEmpty) {
            message = msg.trim();
          }
        }
      } else if (data.containsKey('error')) {
        message = data['error'].toString();
      } else if (data.containsKey('message')) {
        message = data['message'].toString();
      }
    } else if (data is String && data.trim().isNotEmpty) {
      message = data.trim();
    }

    switch (statusCode) {
      case 400:
        return Exception(message);
      case 401:
        return ApiUnauthenticatedException(message.isNotEmpty ? message : 'Unauthorized');
      case 403:
        return Exception('Access forbidden');
      case 404:
        return Exception('Resource not found');
      case 422:
        return Exception(message);
      case 500:
        return Exception('Server error. Please try again later.');
      default:
        return Exception(message);
    }
  }
}
