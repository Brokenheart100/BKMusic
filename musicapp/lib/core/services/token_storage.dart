import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@singleton
class TokenStorage {
  // 使用安全存储
  final _storage = const FlutterSecureStorage();
  final SharedPreferences _prefs; // 注入 SP

  TokenStorage(this._prefs); // 构造函数注入

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _nicknameKey = 'user_nickname'; // 【新增】
  static const _avatarKey = 'user_avatar'; // 【新增】

  Future<void> saveTokens(
      {required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String nickname,
    String? avatarUrl,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);

    // 用户信息存 SP (非敏感数据，读取更快)
    await _prefs.setString(_nicknameKey, nickname);
    if (avatarUrl != null) {
      await _prefs.setString(_avatarKey, avatarUrl);
    } else {
      await _prefs.remove(_avatarKey);
    }
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);
  String? getNickname() => _prefs.getString(_nicknameKey);
  String? getAvatarUrl() => _prefs.getString(_avatarKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _prefs.remove(_nicknameKey);
    await _prefs.remove(_avatarKey);
  }
}
