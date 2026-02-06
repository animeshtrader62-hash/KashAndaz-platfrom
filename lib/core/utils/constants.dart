// ignore_for_file: constant_identifier_names

/// Production API base URL (HTTPS only).
///
/// Do not change to HTTP, IP, or local ports. The Android build enforces HTTPS-only.
const String API_BASE_URL = 'https://api.kashandaz.com';

/// API Constants and Configuration
class ApiConstants {
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
