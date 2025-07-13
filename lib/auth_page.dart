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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64),
                const SizedBox(height: 16),
                Text(
                  'FlClash Login',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
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
                  child: const Text('Login'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    // 跳过登录，直接进入应用
                    setState(() {
                      _isLoggedIn = true;
                    });
                  },
                  child: const Text('Skip (Dev)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}