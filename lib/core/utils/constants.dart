import 'package:flutter/foundation.dart';

/// API Constants and Configuration
class ApiConstants {
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  // Production default. If you don't pass --dart-define=API_BASE_URL=...,
  // the app will use this.
  static const String _defaultBaseUrl = 'https://api.kashandaz.com';

  /// Backend base URL.
  static String get baseUrl {
    final raw = (_baseUrlOverride.isNotEmpty ? _baseUrlOverride : _defaultBaseUrl).trim();
    final normalized = raw.replaceAll(RegExp(r'/+$'), '');

    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('Invalid API_BASE_URL: "$raw"');
    }
    if (uri.scheme != 'https') {
      throw StateError('API_BASE_URL must use HTTPS (got: ${uri.scheme})');
    }

    return normalized;
  }

  // API Endpoints
  static const String authRegister = '/api/auth/register';
  static const String authLogin = '/api/auth/login';
  static const String home = '/api/home';
  static const String stores = '/api/stores';
  static const String activateCashback = '/api/activate-cashback';
  static const String transactions = '/api/transactions';
  static const String wallet = '/api/wallet';
  static const String withdraw = '/api/withdraw';
  static const String profile = '/api/profile';

  // Missing Cashback
  static const String missingCashback = '/api/missing-cashback';
  static const String missingCashbackMy = '/api/missing-cashback/my';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 8);
  static const Duration sendTimeout = Duration(seconds: 8);

  // Headers
  static const String headerAuthorization = 'Authorization';
  static const String headerContentType = 'Content-Type';
  static const String contentTypeJson = 'application/json';
}

/// App-level configuration
class AppConfig {
  /// Set to true during development to bypass login and always show Home.
  /// Set to false for production builds.
  static const bool bypassAuth = false;
}
