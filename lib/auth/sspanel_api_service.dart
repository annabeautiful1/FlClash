import 'dart:convert';
import 'package:dio/dio.dart';

/// SSPanel API 服务类，负责与 bbxy.buzz 后端通信
class SSPanelApiService {
  static const String baseUrl = 'https://bbxy.buzz';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String sendEmailCodeEndpoint = '/auth/send';

  late final Dio _dio;

  SSPanelApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'FlClash-App/1.0',
      },
    ));

    // 添加请求日志（仅在调试模式）
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[SSPanel API] $obj'),
    ));
  }

  /// 登录 API 调用
  Future<ApiResponse> login(String email, String password, {bool rememberMe = false}) async {
    try {
      final response = await _dio.post(
        loginEndpoint,
        data: {
          'email': email.trim().toLowerCase(),
          'passwd': password,
          'remember_me': rememberMe ? '1' : '0',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      return _parseResponse(response.data);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('登录失败：$e');
    }
  }

  /// 注册 API 调用
  Future<ApiResponse> register(
    String name,
    String email,
    String password,
    String emailCode, {
    String? inviteCode,
  }) async {
    try {
      final data = {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'passwd': password,
        'email_code': emailCode.trim(),
      };

      if (inviteCode != null && inviteCode.isNotEmpty) {
        data['invite_code'] = inviteCode.trim();
      }

      final response = await _dio.post(
        registerEndpoint,
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      return _parseResponse(response.data);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('注册失败：$e');
    }
  }

  /// 发送邮箱验证码
  Future<ApiResponse> sendEmailCode(String email) async {
    try {
      final response = await _dio.post(
        sendEmailCodeEndpoint,
        data: {
          'email': email.trim().toLowerCase(),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      return _parseResponse(response.data);
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('发送验证码失败：$e');
    }
  }

  /// 解析 SSPanel API 响应
  ApiResponse _parseResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final ret = data['ret'] as int?;
      final msg = data['msg'] as String? ?? '';

      if (ret == 1) {
        return ApiResponse.success(msg, data);
      } else {
        return ApiResponse.error(msg.isEmpty ? '操作失败' : msg);
      }
    }

    return ApiResponse.error('无效的服务器响应');
  }

  /// 处理 Dio 网络错误
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络';
      case DioExceptionType.sendTimeout:
        return '请求超时，请重试';
      case DioExceptionType.receiveTimeout:
        return '服务器响应超时';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          return '接口不存在';
        } else if (statusCode == 500) {
          return '服务器内部错误';
        }
        return '服务器错误 ($statusCode)';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '网络连接失败，请检查网络设置';
      default:
        return '网络错误：${e.message}';
    }
  }
}

/// API 响应封装类
class ApiResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const ApiResponse._({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.success(String message, [Map<String, dynamic>? data]) {
    return ApiResponse._(
      success: true,
      message: message,
      data: data,
    );
  }

  factory ApiResponse.error(String message) {
    return ApiResponse._(
      success: false,
      message: message,
    );
  }
}

/// 邮箱白名单验证器
class EmailValidator {
  static const List<String> allowedSuffixes = [
    '@qq.com',
    '@gmail.com',
    '@outlook.com',
    '@163.com',
    '@126.com',
    '@yeah.net',
    '@foxmail.com',
    '@sohu.com',
    '@hotmail.com',
    '@live.com',
    '@live.cn',
    '@yahoo.com',
    '@ymail.com',
    '@sina.com',
    '@sina.cn',
  ];

  /// 验证邮箱是否符合格式要求
  static bool isValidFormat(String email) {
    if (email.isEmpty) return false;
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email) && 
           email.length <= 32 && 
           !email.contains('+') && 
           '.'.allMatches(email).length <= 2;
  }

  /// 验证邮箱后缀是否在白名单中
  static bool isAllowedSuffix(String email) {
    if (!isValidFormat(email)) return false;
    
    final lowerEmail = email.toLowerCase();
    return allowedSuffixes.any((suffix) => lowerEmail.endsWith(suffix));
  }

  /// 获取邮箱后缀建议
  static List<String> getSuffixSuggestions(String emailPrefix) {
    if (emailPrefix.isEmpty) return allowedSuffixes;
    
    return allowedSuffixes
        .map((suffix) => '$emailPrefix$suffix')
        .toList();
  }

  /// 获取错误提示信息
  static String? getErrorMessage(String email) {
    if (email.isEmpty) return null;
    
    if (!isValidFormat(email)) {
      return '邮箱格式不正确';
    }
    
    if (!isAllowedSuffix(email)) {
      return '不支持的邮箱后缀，请使用：${allowedSuffixes.join('、')}';
    }
    
    return null;
  }
}