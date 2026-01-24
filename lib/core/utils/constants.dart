import 'package:flutter/foundation.dart';

/// API Constants and Configuration
class ApiConstants {
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Backend base URL.
  /// - Web uses 127.0.0.1 (IPv4 loopback).
  /// - Android emulator must use 10.0.2.2 to reach host machine.
  static String get baseUrl {
    String url;

    if (_baseUrlOverride.isNotEmpty) {
      url = _baseUrlOverride;
    } else if (kIsWeb) {
      url = 'http://127.0.0.1:8000';
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          url = 'http://10.0.2.2:8000';
        default:
          url = 'http://localhost:8000';
      }
    }

    // On Windows, `localhost` may resolve to IPv6 (::1). Uvicorn commonly
    // listens on IPv4 only (0.0.0.0/127.0.0.1), which causes web requests to
    // hang/timeout. Force IPv4 loopback for Flutter web.
    if (kIsWeb) {
      url = url
          .replaceFirst('http://localhost', 'http://127.0.0.1')
          .replaceFirst('https://localhost', 'https://127.0.0.1');
    }

    return url;
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
