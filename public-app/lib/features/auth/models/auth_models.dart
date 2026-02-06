import 'user_model.dart';

/// Authentication response model
class AuthResponse {
  final String token;
  final String? refreshToken;
  final User user;

  AuthResponse({
    required this.token,
    this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final tokenValue = (json['token'] ?? json['access_token'] ?? json['accessToken'])?.toString();
    if (tokenValue == null || tokenValue.trim().isEmpty) {
      throw const FormatException('Login response missing token');
    }

    final userJson = json['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const FormatException('Login response missing user');
    }

    return AuthResponse(
      token: tokenValue,
      refreshToken: (json['refresh_token'] ?? json['refreshToken']) as String?,
      user: User.fromJson(userJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      if (refreshToken != null) 'refresh_token': refreshToken,
      'user': user.toJson(),
    };
  }

  @override
  String toString() => 'AuthResponse(token: ${token.substring(0, 10)}..., user: $user)';
}

/// Login request model
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// Signup request model
class SignupRequest {
  final String name;
  final String email;
  final String password;
  final String phone;

  SignupRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
    };
  }
}
