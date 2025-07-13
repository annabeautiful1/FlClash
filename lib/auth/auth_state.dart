/// 简单的认证状态类，不使用Freezed等代码生成工具
class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? errorMessage;
  final String? token;
  final User? user;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.errorMessage,
    this.token,
    this.user,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? errorMessage,
    String? token,
    User? user,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      token: token ?? this.token,
      user: user ?? this.user,
    );
  }

  AuthState clearError() {
    return copyWith(errorMessage: null);
  }
}

/// 简单的用户信息类
class User {
  final String id;
  final String username;
  final String email;

  const User({
    required this.id,
    required this.username,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
    };
  }
}

/// API响应结果类
class AuthResult {
  final bool success;
  final String? message;
  final String? token;
  final User? user;

  const AuthResult({
    required this.success,
    this.message,
    this.token,
    this.user,
  });

  factory AuthResult.success({String? token, User? user}) {
    return AuthResult(
      success: true,
      token: token,
      user: user,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult(
      success: false,
      message: message,
    );
  }
}