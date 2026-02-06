import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import 'api_client.dart';

/// Provider for SecureStorageService (singleton)
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provider for ApiClient (singleton)
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage);
});

/// Provider to check authentication status
final authStatusProvider = FutureProvider.autoDispose<bool>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return await storage.isAuthenticated();
});
