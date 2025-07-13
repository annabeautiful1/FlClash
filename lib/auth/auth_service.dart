import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_state.dart';

/// 认证服务类，负责与API接口通信
class AuthService {
  // TODO: 替换为实际的API端点
  static const String baseUrl = 'https://your-api-endpoint.com';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  
  // SharedPreferences键名
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_info';
  static const String _isLoggedInKey = 'is_logged_in';

  late final Dio _dio;

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // 添加请求拦截器（可选）
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[AuthService] $obj'),
    ));
  }

  /// 登录API调用
  Future<AuthResult> login(String username, String password) async {
    try {
      final response = await _dio.post(
        loginEndpoint,
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // 假设API返回格式：{"success": true, "token": "...", "user": {...}}
        if (data['success'] == true) {
          final token = data['token'] as String?;
          final userData = data['user'] as Map<String, dynamic>?;
          
          User? user;
          if (userData != null) {
            user = User.fromJson(userData);
          }

          return AuthResult.success(token: token, user: user);
        } else {
          return AuthResult.failure(data['message'] ?? 'Login failed');
        }
      } else {
        return AuthResult.failure('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      return AuthResult.failure(_handleDioError(e));
    } catch (e) {
      return AuthResult.failure('Unexpected error: $e');
    }
  }

  /// 注册API调用
  Future<AuthResult> register(String username, String email, String password) async {
    try {
      final response = await _dio.post(
        registerEndpoint,
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['success'] == true) {
          final token = data['token'] as String?;
          final userData = data['user'] as Map<String, dynamic>?;
          
          User? user;
          if (userData != null) {
            user = User.fromJson(userData);
          }

          return AuthResult.success(token: token, user: user);
        } else {
          return AuthResult.failure(data['message'] ?? 'Registration failed');
        }
      } else {
        return AuthResult.failure('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      return AuthResult.failure(_handleDioError(e));
    } catch (e) {
      return AuthResult.failure('Unexpected error: $e');
    }
  }

  /// 保存认证状态到本地存储
  Future<void> saveAuthState(String? token, User? user) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    }
    
    if (user != null) {
      await prefs.setString(_userKey, json.encode(user.toJson()));
    }
    
    await prefs.setBool(_isLoggedInKey, token != null && user != null);
  }

  /// 从本地存储加载认证状态
  Future<AuthState> loadAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      final token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);
      
      User? user;
      if (userJson != null) {
        final userData = json.decode(userJson) as Map<String, dynamic>;
        user = User.fromJson(userData);
      }

      return AuthState(
        isLoggedIn: isLoggedIn,
        token: token,
        user: user,
      );
    } catch (e) {
      print('[AuthService] Error loading auth state: $e');
      return const AuthState();
    }
  }

  /// 清除认证状态
  Future<void> clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  /// 处理Dio错误
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Request timeout';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'];
        return message ?? 'Server error ($statusCode)';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'Connection error';
      default:
        return 'Network error: ${e.message}';
    }
  }
}