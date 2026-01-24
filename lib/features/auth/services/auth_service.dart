import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/constants.dart';
import '../models/auth_models.dart';
import '../models/user_model.dart';

/// Authentication service for login/signup/logout operations
class AuthService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthService(this._apiClient, this._storage);

  /// Login user
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _apiClient.post(
      ApiConstants.authLogin,
      data: request.toJson(),
    );

    final authResponse = AuthResponse.fromJson(response.data);
    
    // Save token and user data
    await _storage.saveAuthToken(authResponse.token);
    if (authResponse.refreshToken != null && authResponse.refreshToken!.isNotEmpty) {
      await _storage.saveRefreshToken(authResponse.refreshToken!);
    }
    await _storage.saveUserId(authResponse.user.id);
    await _storage.saveUserEmail(authResponse.user.email);

    return authResponse;
  }

  /// Register new user
  Future<AuthResponse> signup(SignupRequest request) async {
    final response = await _apiClient.post(
      ApiConstants.authRegister,
      data: request.toJson(),
    );

    final authResponse = AuthResponse.fromJson(response.data);
    
    // Save token and user data
    await _storage.saveAuthToken(authResponse.token);
    if (authResponse.refreshToken != null && authResponse.refreshToken!.isNotEmpty) {
      await _storage.saveRefreshToken(authResponse.refreshToken!);
    }
    await _storage.saveUserId(authResponse.user.id);
    await _storage.saveUserEmail(authResponse.user.email);

    return authResponse;
  }

  /// Logout user (clear all stored data)
  Future<void> logout() async {
    await _storage.clearAll();
  }

  /// Get current user from storage
  Future<User?> getCurrentUser() async {
    final userId = await _storage.getUserId();
    final email = await _storage.getUserEmail();
    
    if (userId == null || email == null) {
      return null;
    }

    // In real app, you might fetch full user data from API
    // For now, return minimal user object from storage
    return User(
      id: userId,
      name: '', // Will be fetched from profile API later
      email: email,
      phone: '',
    );
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _storage.isAuthenticated();
  }
}
