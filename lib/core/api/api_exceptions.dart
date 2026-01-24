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

class ApiCancelledException implements Exception {
  final String message;

  ApiCancelledException([this.message = 'Request cancelled']);

  @override
  String toString() => message;
}