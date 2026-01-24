import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../core/api/providers.dart';
import '../../../core/utils/constants.dart';
import '../models/auth_models.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthService(apiClient, storage);
});

/// State notifier for authentication state
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  /// Check if user is already authenticated on app start
  Future<void> _checkAuthStatus() async {
    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        final user = await _authService.getCurrentUser();
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      // If storage fails (common on web), just show login
      state = const AsyncValue.data(null);
    }
  }

  /// Login user
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _authService
          .login(request)
          .timeout(ApiConstants.receiveTimeout);
      state = AsyncValue.data(response.user);
    } on TimeoutException catch (e, stack) {
      state = AsyncValue.error(e, stack);
      throw Exception('Login timed out. Please check internet/server and try again.');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Signup user
  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final request = SignupRequest(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      final response = await _authService
          .signup(request)
          .timeout(ApiConstants.receiveTimeout);
      state = AsyncValue.data(response.user);
    } on TimeoutException catch (e, stack) {
      state = AsyncValue.error(e, stack);
      throw Exception('Signup timed out. Please check internet/server and try again.');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
  }
}

/// Provider for auth state
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
