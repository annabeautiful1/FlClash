import 'package:flutter/material.dart';
import 'auth_manager.dart';
import 'login_page.dart';

/// 认证包装器，根据登录状态决定显示登录页面还是主应用
class AuthWrapper extends StatelessWidget {
  final Widget child;

  const AuthWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AuthManager(),
      builder: (context, authState, _) {
        // 如果已登录，显示主应用
        if (authState.isLoggedIn) {
          return child;
        }
        
        // 未登录时显示登录页面
        return const LoginPage();
      },
    );
  }
}