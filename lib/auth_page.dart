import 'package:flutter/material.dart';

/// 极简的认证页面，只包含基础UI，无外部依赖
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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _confirmPasswordController.dispose();
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
            child: _isLoginPage ? _buildLoginPage() : _buildRegisterPage(),
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
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: '用户名或邮箱',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '密码',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            // 简单的模拟登录
            setState(() {
              _isLoggedIn = true;
            });
          },
          child: const Text('登录'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            // 跳过登录，直接进入应用
            setState(() {
              _isLoggedIn = true;
            });
          },
          child: const Text('跳过'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
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
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: '用户名',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: '邮箱',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '密码',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '确认密码',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            // 简单的模拟注册
            setState(() {
              _isLoggedIn = true;
            });
          },
          child: const Text('注册'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _isLoginPage = true;
            });
          },
          child: const Text('已有账号？返回登录'),
        ),
      ],
    );
  }
}