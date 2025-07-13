import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'generated/auth.freezed.dart';
part 'generated/auth.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String username,
    required String email,
    DateTime? lastLoginAt,
    DateTime? createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    User? currentUser,
    @Default(false) bool isLoading,
    @Default(false) bool isLoggedIn,
    String? errorMessage,
  }) = _AuthState;

  factory AuthState.fromJson(Map<String, dynamic> json) => _$AuthStateFromJson(json);
}

@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String usernameOrEmail,
    required String password,
    @Default(false) bool rememberMe,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
}

@freezed
class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);
}

@freezed
class AuthError with _$AuthError {
  const factory AuthError({
    required String message,
    required AuthErrorType type,
    Map<String, String>? fieldErrors,
  }) = _AuthError;

  factory AuthError.fromJson(Map<String, dynamic> json) => _$AuthErrorFromJson(json);
}

enum AuthErrorType {
  invalidCredentials,
  userNotFound,
  emailAlreadyExists,
  usernameAlreadyExists,
  weakPassword,
  invalidEmail,
  networkError,
  serverError,
  validationError,
}