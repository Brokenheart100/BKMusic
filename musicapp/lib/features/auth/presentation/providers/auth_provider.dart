import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:logger/logger.dart'; // 1. 引入 Logger
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/core/services/token_storage.dart';
import 'package:music_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:music_app/features/music_player/data/datasources/media_api.dart';
import 'package:music_app/features/music_player/data/models/media_dto.dart';

class UserProfile {
  final String email;
  final String nickname;
  final String? avatarUrl;

  const UserProfile(
      {required this.email, // 必填
      required this.nickname,
      this.avatarUrl});
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
  final MediaApi _mediaApi = getIt<MediaApi>();

  // 3. 获取 Logger 实例
  final Logger _logger = getIt<Logger>();

  AuthController(this._ref);

  Future<String?> uploadAvatar(File file) async {
    _logger.i("📸 [Auth] 开始上传头像流程...");
    try {
      // 1. 获取上传链接
      final request = InitUploadRequest(
          songId: null,
          fileName: "avatar_${DateTime.now().millisecondsSinceEpoch}.jpg",
          contentType: "image/jpeg",
          category: "avatar");

      _logger.d("📤 [Auth] 请求上传链接: ${request.fileName}");
      final initRes = await _mediaApi.initUpload(request);

      if (!initRes.isSuccess || initRes.value == null) {
        _logger.w("⚠️ [Auth] 获取上传链接失败: ${initRes.error}");
        return null;
      }
      final data = initRes.value!;

      // 2. 物理上传
      _logger.d("⬆️ [Auth] 开始物理上传至 MinIO: ${data.uploadUrl}");
      final rawDio = Dio();
      await rawDio.put(data.uploadUrl,
          data: file.openRead(),
          options: Options(headers: {
            "Content-Type": "image/jpeg",
            "Content-Length": await file.length()
          }));

      // 3. 确认上传
      _logger.d("✔️ [Auth] 确认上传: ${data.uploadId}");
      await _mediaApi.confirmUpload({"uploadId": data.uploadId});

      // 4. 拼接 URL
      final finalUrl = "http://localhost:9000/music-raw/${data.key}";
      _logger.i("✅ [Auth] 头像上传成功: $finalUrl");

      return finalUrl;
    } catch (e, stack) {
      _logger.e("❌ [Auth] 头像上传发生异常", error: e, stackTrace: stack);
      return null;
    }
  }

  // 初始化检查登录状态
  Future<void> checkLoginStatus() async {
    _logger.d("🔍 [Auth] 正在检查登录状态...");
    try {
      final isLoggedIn = await _repository.isLoggedIn();

      if (isLoggedIn) {
        final nickname = _storage.getNickname() ?? "User";
        final avatar = _storage.getAvatarUrl();
        final email = _storage.getEmail() ?? "user@example.com";
        _ref.read(currentUserProvider.notifier).state =
            UserProfile(email: email, nickname: nickname, avatarUrl: avatar);

        _logger.i("✅ [Auth] 用户已登录: $nickname");
      } else {
        _logger.i("⚪ [Auth] 用户未登录");
      }

      _ref.read(authStateProvider.notifier).state = isLoggedIn;
    } catch (e) {
      _logger.e("❌ [Auth] 检查登录状态出错", error: e);
      // 出错视为未登录
      _ref.read(authStateProvider.notifier).state = false;
    }
  }

  Future<void> login(String email, String password) async {
    _logger.i("🔐 [Auth] 尝试登录: $email");
    try {
      final response = await _repository.login(email, password);

      _ref.read(currentUserProvider.notifier).state = UserProfile(
          email: email, // 【新增】直接使用登录时的 email
          nickname: response.nickname,
          avatarUrl: response.avatarUrl);

      // 2. 更新本地存储 (补全 Email)
      await _storage.saveAuthData(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        nickname: response.nickname,
        avatarUrl: response.avatarUrl,
        email: email, // 【新增】传入 email
      );

      _ref.read(authStateProvider.notifier).state = true;
      _logger.i("✅ [Auth] 登录成功! 欢迎回来, ${response.nickname}");
    } catch (e, stack) {
      _logger.e("❌ [Auth] 登录失败", error: e, stackTrace: stack);
      rethrow; // 抛出异常供 UI 层 (LoginPage) 显示 SnackBar
    }
  }

  Future<void> register(
      String email, String password, String nickname, String? avatarUrl) async {
    _logger.i("📝 [Auth] 尝试注册: $email, Nickname: $nickname");
    try {
      await _repository.register(email, password, nickname, avatarUrl);
      _logger.i("✅ [Auth] 注册成功");
    } catch (e, stack) {
      _logger.e("❌ [Auth] 注册失败", error: e, stackTrace: stack);
      rethrow; // 抛出异常供 UI 层显示
    }
  }

  Future<void> logout() async {
    _logger.i("🚪 [Auth] 用户登出");
    try {
      await _repository.logout();
      _ref.read(currentUserProvider.notifier).state = null;
      _ref.read(authStateProvider.notifier).state = false;
    } catch (e) {
      _logger.w("⚠️ [Auth] 登出清理时发生轻微错误", error: e);
      // 强制清理状态，保证用户能退出
      _ref.read(authStateProvider.notifier).state = false;
    }
  }
}
