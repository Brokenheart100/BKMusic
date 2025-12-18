import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/auth/presentation/providers/auth_provider.dart';

/// 这是一个胶水类，将 Riverpod 的状态变化转换为 GoRouter 能听懂的 notifyListeners
class AuthListenable extends ChangeNotifier {
  final Ref ref;

  AuthListenable(this.ref) {
    // 监听 authStateProvider 的变化
    // 每当登录状态改变 (true/false)，就通知 GoRouter 重新评估重定向逻辑
    ref.listen<bool>(
      authStateProvider,
      (previous, next) {
        notifyListeners();
      },
    );
  }
}

// 定义一个 Provider 来提供这个监听器
final authListenableProvider = Provider<AuthListenable>((ref) {
  return AuthListenable(ref);
});
