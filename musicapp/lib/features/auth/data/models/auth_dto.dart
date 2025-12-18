import 'package:json_annotation/json_annotation.dart';

part 'auth_dto.g.dart';

// 登录请求
@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

// 注册请求
@JsonSerializable()
class RegisterRequest {
  final String email;
  final String password;
  final String nickname;
  final String? avatarUrl;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.nickname,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

// 认证响应 (包含 Token)
@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  // 【新增】
  final String nickname;
  final String? avatarUrl;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.nickname,
    this.avatarUrl,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}
