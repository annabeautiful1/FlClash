import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'auth/sspanel_api_service.dart';

/// SSPanel 集成的认证页面
class AuthPage extends StatefulWidget {
  final Widget child;

  const AuthPage({
    super.key,
    required this.child,
  });

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLoggedIn = false;
  bool _isLoginPage = true; // true: 登录页面, false: 注册页面
  bool _isLoading = false;
  String? _errorMessage;

  // 表单控制器
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailCodeController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  // 验证码倒计时
  bool _canSendCode = true;
  int _countdownSeconds = 60;
  Timer? _countdownTimer;

  // API 服务
  final _apiService = SSPanelApiService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    _emailCodeController.dispose();
    _inviteCodeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return widget.child;
    }

    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: _isLoginPage ? _buildLoginPage() : _buildRegisterPage(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPage() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_outline, size: 64),
        const SizedBox(height: 16),
        Text(
          'FlClash 登录',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),

        // 邮箱输入
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: '邮箱',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入邮箱';
            }
            final errorMessage = EmailValidator.getErrorMessage(value.trim());
            return errorMessage;
          },
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),

        // 密码输入
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '密码',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入密码';
            }
            return null;
          },
          enabled: !_isLoading,
          onFieldSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 24),

        // 错误信息显示
        if (_errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 16,
                  ),
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 登录按钮
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('登录'),
          ),
        ),
        const SizedBox(height: 8),

        // 跳过按钮（开发用）
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _handleSkipLogin,
            child: const Text('跳过（开发模式）'),
          ),
        ),
        const SizedBox(height: 16),

        // 注册链接
        TextButton(
          onPressed: _isLoading ? null : () {
            _clearForm();
            setState(() {
              _isLoginPage = false;
            });
          },
          child: const Text('还没有账号？点击注册'),
        ),
      ],
    );
  }

  Widget _buildRegisterPage() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.person_add_outlined, size: 64),
        const SizedBox(height: 16),
        Text(
          'FlClash 注册',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),

        // 用户名输入
        TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: '用户名',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入用户名';
            }
            return null;
          },
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),

        // 邮箱输入（带白名单验证）
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: '邮箱',
            prefixIcon: const Icon(Icons.email_outlined),
            border: const OutlineInputBorder(),
            helperText: '支持：${EmailValidator.allowedSuffixes.take(3).join('、')} 等',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入邮箱';
            }
            final errorMessage = EmailValidator.getErrorMessage(value.trim());
            return errorMessage;
          },
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),

        // 密码输入
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '密码',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
            helperText: '至少8位字符',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入密码';
            }
            if (value.length < 8) {
              return '密码至少需要8位字符';
            }
            return null;
          },
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),

        // 确认密码输入
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '确认密码',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请确认密码';
            }
            if (value != _passwordController.text) {
              return '两次密码输入不一致';
            }
            return null;
          },
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),

        // 邮箱验证码输入
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailCodeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  labelText: '邮箱验证码',
                  prefixIcon: Icon(Icons.verified_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入验证码';
                  }
                  if (value.trim().length != 6) {
                    return '验证码为6位数字';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: OutlinedButton(
                onPressed: (_canSendCode && !_isLoading) ? _handleSendEmailCode : null,
                child: Text(_canSendCode ? '发送验证码' : '$_countdownSeconds秒'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 邀请码输入（可选）
        TextFormField(
          controller: _inviteCodeController,
          decoration: const InputDecoration(
            labelText: '邀请码（可选）',
            prefixIcon: Icon(Icons.card_giftcard_outlined),
            border: OutlineInputBorder(),
          ),
          enabled: !_isLoading,
        ),
        const SizedBox(height: 24),

        // 错误信息显示
        if (_errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 16,
                  ),
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 注册按钮
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isLoading ? null : _handleRegister,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('注册'),
          ),
        ),
        const SizedBox(height: 16),

        // 返回登录链接
        TextButton(
          onPressed: _isLoading ? null : () {
            _clearForm();
            setState(() {
              _isLoginPage = true;
            });
          },
          child: const Text('已有账号？返回登录'),
        ),
      ],
    );
  }

  // 清理表单
  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _usernameController.clear();
    _confirmPasswordController.clear();
    _emailCodeController.clear();
    _inviteCodeController.clear();
    setState(() {
      _errorMessage = null;
    });
  }

  // 处理登录
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (response.success) {
        setState(() {
          _isLoggedIn = true;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '登录失败：$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 处理注册
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _emailCodeController.text.trim(),
        inviteCode: _inviteCodeController.text.trim().isEmpty 
            ? null 
            : _inviteCodeController.text.trim(),
      );

      if (response.success) {
        setState(() {
          _isLoggedIn = true;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '注册失败：$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 处理发送邮箱验证码
  Future<void> _handleSendEmailCode() async {
    final email = _emailController.text.trim();
    final errorMessage = EmailValidator.getErrorMessage(email);
    
    if (errorMessage != null) {
      setState(() {
        _errorMessage = errorMessage;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.sendEmailCode(email);

      if (response.success) {
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '发送验证码失败：$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 开始验证码倒计时
  void _startCountdown() {
    setState(() {
      _canSendCode = false;
      _countdownSeconds = 60;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownSeconds--;
      });

      if (_countdownSeconds <= 0) {
        setState(() {
          _canSendCode = true;
        });
        timer.cancel();
      }
    });
  }

  // 跳过登录（开发模式）
  void _handleSkipLogin() {
    setState(() {
      _isLoggedIn = true;
    });
  }
}