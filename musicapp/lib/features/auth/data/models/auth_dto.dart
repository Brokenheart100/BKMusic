import 'package:json_annotation/json_annotation.dart';

part 'auth_dto.g.dart';

// 登录请求
@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);

  // 【新增】补全 fromJson，消除 _$LoginRequestFromJson 未使用的警告
  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
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

  // 【新增】补全 fromJson，消除 _$RegisterRequestFromJson 未使用的警告
  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
}

// 认证响应
@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String refreshToken;
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

  // 【新增】补全 toJson，消除 _$AuthResponseToJson 未使用的警告
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
