import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import '../storage/secure_storage.dart';
import '../utils/constants.dart';

/// HTTP interceptor for adding auth headers and logging
class ApiInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Logger _logger = Logger(
    level: kDebugMode ? Level.debug : Level.off,
  );

  ApiInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token to headers if available
    final token = await _storage.getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers[ApiConstants.headerAuthorization] = 'Bearer $token';
    }

    // Add content type (don't override multipart/form-data)
    if (options.data is! FormData) {
      options.headers[ApiConstants.headerContentType] = ApiConstants.contentTypeJson;
    }

    if (kDebugMode) {
      final headers = Map<String, dynamic>.from(options.headers);
      if (headers.containsKey(ApiConstants.headerAuthorization)) {
        headers[ApiConstants.headerAuthorization] = 'Bearer ***';
      }

      _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
      _logger.d('Headers: $headers');
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.i(
        'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
      );
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.e(
        'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
      );
      _logger.e('Message: ${err.message}');
    }

    // Treat 401 as unauthenticated (not a network problem). Clear stale tokens so
    // guest-access endpoints don't keep failing due to an invalid token.
    if (err.response?.statusCode == 401) {
      unawaited(_storage.clearAll());
    }

    return handler.next(err);
  }
}
