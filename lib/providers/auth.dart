import 'dart:convert';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/common/common.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

part 'generated/auth.g.dart';

const String _authStateKey = 'auth_state';
const String _userCredentialsKey = 'user_credentials';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    _loadAuthState();
    return const AuthState();
  }

  Future<void> _loadAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authStateJson = prefs.getString(_authStateKey);
      if (authStateJson != null) {
        final authState = AuthState.fromJson(json.decode(authStateJson));
        state = authState;
      }
    } catch (e) {
      debugPrint('Failed to load auth state: $e');
    }
  }

  Future<void> _saveAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authStateKey, json.encode(state.toJson()));
    } catch (e) {
      debugPrint('Failed to save auth state: $e');
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> login(LoginRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 模拟登录验证逻辑
      await Future.delayed(const Duration(seconds: 1));

      // 从本地存储获取用户凭据
      final prefs = await SharedPreferences.getInstance();
      final credentialsJson = prefs.getString(_userCredentialsKey);
      
      if (credentialsJson == null) {
        throw const AuthError(
          message: 'User not found',
          type: AuthErrorType.userNotFound,
        );
      }

      final credentials = json.decode(credentialsJson);
      final storedUsername = credentials['username'] as String;
      final storedEmail = credentials['email'] as String;
      final storedPasswordHash = credentials['passwordHash'] as String;

      // 验证用户名或邮箱
      final isValidUser = request.usernameOrEmail == storedUsername || 
                         request.usernameOrEmail == storedEmail;
      
      if (!isValidUser || _hashPassword(request.password) != storedPasswordHash) {
        throw const AuthError(
          message: 'Invalid credentials',
          type: AuthErrorType.invalidCredentials,
        );
      }

      // 创建用户对象
      final user = User(
        id: credentials['id'] as String,
        username: storedUsername,
        email: storedEmail,
        lastLoginAt: DateTime.now(),
        createdAt: DateTime.parse(credentials['createdAt'] as String),
      );

      state = state.copyWith(
        currentUser: user,
        isLoggedIn: true,
        isLoading: false,
        errorMessage: null,
      );

      await _saveAuthState();
    } on AuthError catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  Future<void> register(RegisterRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 验证表单
      if (request.password != request.confirmPassword) {
        throw const AuthError(
          message: 'Passwords do not match',
          type: AuthErrorType.validationError,
          fieldErrors: {'confirmPassword': 'Passwords do not match'},
        );
      }

      if (request.password.length < 6) {
        throw const AuthError(
          message: 'Password must be at least 6 characters',
          type: AuthErrorType.weakPassword,
          fieldErrors: {'password': 'Password must be at least 6 characters'},
        );
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(request.email)) {
        throw const AuthError(
          message: 'Invalid email format',
          type: AuthErrorType.invalidEmail,
          fieldErrors: {'email': 'Invalid email format'},
        );
      }

      // 模拟注册过程
      await Future.delayed(const Duration(seconds: 1));

      // 检查是否已存在用户
      final prefs = await SharedPreferences.getInstance();
      final existingCredentials = prefs.getString(_userCredentialsKey);
      
      if (existingCredentials != null) {
        final credentials = json.decode(existingCredentials);
        final storedUsername = credentials['username'] as String;
        final storedEmail = credentials['email'] as String;
        
        if (storedUsername == request.username) {
          throw const AuthError(
            message: 'Username already exists',
            type: AuthErrorType.usernameAlreadyExists,
            fieldErrors: {'username': 'Username already exists'},
          );
        }
        
        if (storedEmail == request.email) {
          throw const AuthError(
            message: 'Email already exists',
            type: AuthErrorType.emailAlreadyExists,
            fieldErrors: {'email': 'Email already exists'},
          );
        }
      }

      // 创建新用户
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      final createdAt = DateTime.now();
      
      final user = User(
        id: userId,
        username: request.username,
        email: request.email,
        lastLoginAt: createdAt,
        createdAt: createdAt,
      );

      // 保存用户凭据
      final credentials = {
        'id': userId,
        'username': request.username,
        'email': request.email,
        'passwordHash': _hashPassword(request.password),
        'createdAt': createdAt.toIso8601String(),
      };

      await prefs.setString(_userCredentialsKey, json.encode(credentials));

      state = state.copyWith(
        currentUser: user,
        isLoggedIn: true,
        isLoading: false,
        errorMessage: null,
      );

      await _saveAuthState();
    } on AuthError catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authStateKey);
      
      state = const AuthState();
    } catch (e) {
      debugPrint('Failed to logout: $e');
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

@riverpod
AuthNotifier authNotifier(AuthNotifierRef ref) {
  return AuthNotifier();
}

@riverpod
AuthState authState(AuthStateRef ref) {
  return ref.watch(authNotifierProvider);
}

@riverpod
bool isLoggedIn(IsLoggedInRef ref) {
  return ref.watch(authStateProvider.select((state) => state.isLoggedIn));
}

@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(authStateProvider.select((state) => state.currentUser));
}