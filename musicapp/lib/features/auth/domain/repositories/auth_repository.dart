import 'package:music_app/features/auth/data/models/auth_dto.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String email, String password);
  Future<void> register(
      String email, String password, String nickname, String? avatarUrl);
  Future<void> logout();
  Future<bool> isLoggedIn();
}
