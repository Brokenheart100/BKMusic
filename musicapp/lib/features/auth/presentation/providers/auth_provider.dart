import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/core/services/token_storage.dart';
import 'package:music_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String nickname;
  final String? avatarUrl;
  const UserProfile({required this.nickname, this.avatarUrl});
}

final currentUserProvider = StateProvider<UserProfile?>((ref) => null);

// 1. 认证状态 Provider (是否已登录)
final authStateProvider = StateProvider<bool>((ref) => false);

// 2. Auth 控制器 Provider
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

class AuthController {
  final Ref _ref;
  final AuthRepository _repository = getIt<AuthRepository>();
  final _storage = getIt<TokenStorage>();

  AuthController(this._ref);

  // 初始化检查登录状态
  Future<void> checkLoginStatus() async {
    final isLoggedIn = await _repository.isLoggedIn();
    if (isLoggedIn) {
      // 【新增】恢复用户信息到状态中
      final nickname = _storage.getNickname() ?? "User";
      final avatar = _storage.getAvatarUrl();
      _ref.read(currentUserProvider.notifier).state =
          UserProfile(nickname: nickname, avatarUrl: avatar);
    }
    _ref.read(authStateProvider.notifier).state = isLoggedIn;
  }

  Future<void> login(String email, String password) async {
    final response = await _repository.login(email, password);

    // 【新增】登录成功后立即更新状态
    _ref.read(currentUserProvider.notifier).state =
        UserProfile(nickname: response.nickname, avatarUrl: response.avatarUrl);

    _ref.read(authStateProvider.notifier).state = true;
  }

  Future<void> register(
      String email, String password, String nickname, String? avatarUrl) async {
    await _repository.register(email, password, nickname, avatarUrl);
    // 注册后通常需要重新登录，或者直接调用 login
  }

  Future<void> logout() async {
    await _repository.logout();
    _ref.read(currentUserProvider.notifier).state = null; // 清空用户
    _ref.read(authStateProvider.notifier).state = false;
  }
}
