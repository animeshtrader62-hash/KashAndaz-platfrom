import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';
import '../utils/constants.dart';
import 'api_interceptor.dart';
import 'api_exceptions.dart';

/// HTTP client for API calls
class ApiClient {
  late final Dio _dio;
  final SecureStorageService _storage;

  ApiClient(this._storage) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[ApiClient] baseUrl=$API_BASE_URL');
    }

    _dio = Dio(
      BaseOptions(
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

  String _resolveUrl(String path) {
    final trimmed = path.trim();
    if (trimmed.startsWith('http://')) {
      throw StateError('HTTP is not allowed. Use HTTPS only.');
    }
    if (trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (!trimmed.startsWith('/')) {
      // Keep behavior explicit to avoid accidental relative URLs.
      return '$API_BASE_URL/$trimmed';
    }
    return '$API_BASE_URL$trimmed';
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
        _resolveUrl(path),
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
        _resolveUrl(path),
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
        _resolveUrl(path),
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
        _resolveUrl(path),
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
        return ApiTimeoutException('Request timed out. Please try again.');
      
      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);
      
      case DioExceptionType.cancel:
        return ApiCancelledException('Request cancelled');
      
      case DioExceptionType.connectionError:
        return ApiNetworkException('No Internet connection');
      
      default:
        final msg = (error.message ?? '').toLowerCase();
        // TLS / DNS / routing failures must be treated as connectivity problems.
        if (msg.contains('handshake') ||
            msg.contains('certificate') ||
            msg.contains('tls') ||
            msg.contains('ssl')) {
          return ApiNetworkException('No Internet connection');
        }
        if (msg.contains('failed host lookup') ||
            msg.contains('network is unreachable') ||
            msg.contains('connection refused') ||
            msg.contains('no address associated with hostname')) {
          return ApiNetworkException('No Internet connection');
        }
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
        return ApiHttpException(message, statusCode: statusCode);
      case 401:
        return ApiUnauthenticatedException(message.isNotEmpty ? message : 'Unauthorized');
      case 403:
        return ApiHttpException(message.isNotEmpty ? message : 'Access forbidden', statusCode: statusCode);
      case 404:
        return ApiHttpException(message.isNotEmpty ? message : 'Resource not found', statusCode: statusCode);
      case 422:
        return ApiHttpException(message, statusCode: statusCode);
      case 500:
        return ApiServerException('Server error. Please try again later.');
      default:
        if (statusCode != null && statusCode >= 500) {
          return ApiServerException('Server temporarily unavailable. Please try again later.');
        }
        if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          return ApiHttpException(message, statusCode: statusCode);
        }
        return Exception(message);
    }
  }
}
