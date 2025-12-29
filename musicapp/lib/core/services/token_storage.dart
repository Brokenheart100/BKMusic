import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

@singleton
class TokenStorage {
  // 暂时保留引用，但调试期间我们优先使用 SharedPreferences
  final _storage = const FlutterSecureStorage();
  final SharedPreferences _prefs;

  // 获取全局 Logger
  final Logger _logger = getIt<Logger>();

  TokenStorage(this._prefs);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _nicknameKey = 'user_nickname';
  static const _avatarKey = 'user_avatar';
  static const _emailKey = 'user_email';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _logger.d("💾 [TokenStorage] 正在保存 Token...");
    // 【调试修改】改用 SharedPreferences 存储 Token，确保 Windows 兼容性
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
    // await _storage.write(key: _accessTokenKey, value: accessToken);
    // await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String nickname,
    String? avatarUrl,
    required String email,
  }) async {
    // 1. 存 Token
    await saveTokens(accessToken: accessToken, refreshToken: refreshToken);

    // 2. 存用户信息
    await _prefs.setString(_nicknameKey, nickname);
    await _prefs.setString(_emailKey, email);
    if (avatarUrl != null) {
      await _prefs.setString(_avatarKey, avatarUrl);
    } else {
      await _prefs.remove(_avatarKey);
    }
    _logger.i("✅ [TokenStorage] 认证数据保存完毕: $nickname");
  }

  // 【调试修改】从 SharedPreferences 读取
  Future<String?> getAccessToken() async {
    final token = _prefs.getString(_accessTokenKey);
    // final token = await _storage.read(key: _accessTokenKey);

    if (token == null) {
      _logger.w("⚠️ [TokenStorage] 读取 AccessToken 为空!");
    } else {
      // 只打印前10位，防止日志泄露完整 Token
      _logger.t(
          "🔍 [TokenStorage] 读取 AccessToken 成功: ${token.substring(0, 10)}...");
    }
    return token;
  }

  Future<String?> getRefreshToken() async {
    return _prefs.getString(_refreshTokenKey);
    // return _storage.read(key: _refreshTokenKey);
  }

  String? getNickname() => _prefs.getString(_nicknameKey);
  String? getAvatarUrl() => _prefs.getString(_avatarKey);
  String? getEmail() => _prefs.getString(_emailKey);

  Future<void> clearTokens() async {
    _logger.i("🧹 [TokenStorage] 清理所有认证数据");
    // 清理两边，防止混乱
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);

    await _prefs.remove(_nicknameKey);
    await _prefs.remove(_avatarKey);
  }
}
