import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../storage/secure_storage.dart';
import '../utils/constants.dart';

/// HTTP interceptor for adding auth headers and logging
class ApiInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Logger _logger = Logger();

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

    // Add content type
    options.headers[ApiConstants.headerContentType] = ApiConstants.contentTypeJson;

    // Log request
    _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
    _logger.d('Headers: ${options.headers}');
    if (options.data != null) {
      _logger.d('Body: ${options.data}');
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    _logger.d('Data: ${response.data}');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );
    _logger.e('Message: ${err.message}');
    if (err.response?.data != null) {
      _logger.e('Error Data: ${err.response?.data}');
    }

    return handler.next(err);
  }
}
