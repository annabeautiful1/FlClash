import 'package:flutter/foundation.dart';
import 'auth_state.dart';
import 'auth_service.dart';

/// 认证管理器，使用ValueNotifier进行简单的状态管理
class AuthManager extends ValueNotifier<AuthState> {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  
  AuthManager._internal() : super(const AuthState()) {
    _initialize();
  }

  final AuthService _authService = AuthService();

  /// 初始化，加载保存的认证状态
  Future<void> _initialize() async {
    final savedState = await _authService.loadAuthState();
    value = savedState;
  }

  /// 登录
  Future<void> login(String username, String password) async {
    // 设置加载状态
    value = value.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _authService.login(username, password);
      
      if (result.success) {
        // 保存认证信息
        await _authService.saveAuthState(result.token, result.user);
        
        // 更新状态
        value = value.copyWith(
          isLoggedIn: true,
          isLoading: false,
          token: result.token,
          user: result.user,
          errorMessage: null,
        );
      } else {
        value = value.copyWith(
          isLoading: false,
          errorMessage: result.message ?? 'Login failed',
        );
      }
    } catch (e) {
      value = value.copyWith(
        isLoading: false,
        errorMessage: 'Login failed: $e',
      );
    }
  }

  /// 注册
  Future<void> register(String username, String email, String password) async {
    value = value.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _authService.register(username, email, password);
      
      if (result.success) {
        await _authService.saveAuthState(result.token, result.user);
        
        value = value.copyWith(
          isLoggedIn: true,
          isLoading: false,
          token: result.token,
          user: result.user,
          errorMessage: null,
        );
      } else {
        value = value.copyWith(
          isLoading: false,
          errorMessage: result.message ?? 'Registration failed',
        );
      }
    } catch (e) {
      value = value.copyWith(
        isLoading: false,
        errorMessage: 'Registration failed: $e',
      );
    }
  }

  /// 登出
  Future<void> logout() async {
    await _authService.clearAuthState();
    value = const AuthState();
  }

  /// 清除错误信息
  void clearError() {
    value = value.clearError();
  }

  /// 检查是否已登录
  bool get isLoggedIn => value.isLoggedIn;

  /// 获取当前用户
  User? get currentUser => value.user;

  /// 获取访问令牌
  String? get token => value.token;
}