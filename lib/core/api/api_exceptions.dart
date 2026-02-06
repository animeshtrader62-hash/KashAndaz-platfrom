class ApiUnauthenticatedException implements Exception {
  final String message;

  ApiUnauthenticatedException([this.message = 'Unauthenticated']);

  @override
  String toString() => message;
}

class ApiNetworkException implements Exception {
  final String message;

  ApiNetworkException([this.message = 'No internet connection']);

  @override
  String toString() => message;
}

class ApiTimeoutException implements Exception {
  final String message;

  ApiTimeoutException([this.message = 'Connection timeout']);

  @override
  String toString() => message;
}

class ApiServerException implements Exception {
  final String message;

  ApiServerException([this.message = 'Server error. Please try again later.']);

  @override
  String toString() => message;
}

/// Represents a handled HTTP error where the backend returned a message (typically 4xx).
class ApiHttpException implements Exception {
  final int? statusCode;
  final String message;

  ApiHttpException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiCancelledException implements Exception {
  final String message;

  ApiCancelledException([this.message = 'Request cancelled']);

  @override
  String toString() => message;
}