import 'package:injectable/injectable.dart';
// Token 存储服务：负责本地持久化/读取/清理 AccessToken/RefreshToken
import 'package:music_app/core/services/token_storage.dart';
// 认证 API 接口：封装登录/注册的网络请求
import 'package:music_app/features/auth/data/datasources/auth_api.dart';
// 认证相关 DTO：请求/响应数据模型（LoginRequest/RegisterRequest/AuthResponse）
import 'package:music_app/features/auth/data/models/auth_dto.dart';
// 认证仓库抽象接口：定义业务层需要的认证能力（由本类实现）
import 'package:music_app/features/auth/domain/repositories/auth_repository.dart';

/// 认证仓库实现类（核心业务层实现）
/// 注解说明：
/// - @LazySingleton：依赖注入注解（injectable 库），标记此类为「懒汉单例」
///   - 懒加载：首次使用时才实例化，优化启动性能
///   - as: AuthRepository：将此类注册为 AuthRepository 接口的实现类，便于依赖注入时解耦
/// 设计思路：
/// - 实现 domain 层的 AuthRepository 抽象接口，隔离数据层细节（API/本地存储）
/// - 封装「网络请求 + 本地 Token 管理」的核心认证逻辑，对外暴露简洁的业务方法
/// - 统一异常处理，将底层异常（网络/存储）向上抛，由上层（ViewModel/Bloc）处理
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  // 私有成员：认证 API 实例（由依赖注入自动注入）
  final AuthApi _api;
  // 私有成员：Token 存储服务实例（由依赖注入自动注入）
  final TokenStorage _tokenStorage;

  /// 构造函数（依赖注入）
  /// 参数由 injectable 自动注入，无需手动创建实例
  /// - _api：已配置的 AuthApi 实例（包含 Dio 全局配置）
  /// - _tokenStorage：已实现的 Token 存储服务（如基于 SharedPreferences/FlutterSecureStorage）
  AuthRepositoryImpl(this._api, this._tokenStorage);

  /// 登录业务方法（实现接口定义）
  /// 核心流程：参数封装 → 调用登录 API → 校验响应 → 持久化 Token → 返回结果
  /// 参数：
  ///   - email：用户邮箱（登录账号）
  ///   - password：用户密码（明文/已加密，取决于后端要求）
  /// 返回值：AuthResponse - 包含 Token、用户信息等登录成功数据
  /// 异常：抛出 Exception，包含具体错误描述
  @override
  Future<AuthResponse> login(String email, String password) async {
    try {
      // 1. 封装登录请求参数（DTO 转换）
      // 将业务层的简单参数（email/password）封装为 API 层需要的 LoginRequest 对象
      final response =
          await _api.login(LoginRequest(email: email, password: password));

      // 2. 校验 API 响应是否成功
      // isSuccess：通用响应模型 ApiResponse 的扩展属性，判断接口是否返回成功码
      // response.value：登录成功的核心数据（AuthResponse，包含 accessToken/refreshToken）
      if (response.isSuccess && response.value != null) {
        // 3. 【核心操作】登录成功后持久化 Token
        // Token 是后续接口鉴权的核心，需本地存储（如 SharedPreferences/安全存储）
        await _tokenStorage.saveTokens(
          accessToken: response.value!.accessToken, // 访问令牌（短期有效）
          refreshToken:
              response.value!.refreshToken, // 刷新令牌（长期有效，用于刷新 accessToken）
        );
        await _tokenStorage.saveAuthData(
          accessToken: response.value!.accessToken,
          refreshToken: response.value!.refreshToken,
          nickname: response.value!.nickname,
          avatarUrl: response.value!.avatarUrl,
        );
        // 4. 返回登录成功数据给上层
        return response.value!;
      } else {
        // 5. 接口返回失败（如账号密码错误），抛出业务异常
        // response.error?.description：后端返回的具体错误信息（如「密码错误」）
        // 兜底信息：Login failed，避免错误信息为空
        throw Exception(response.error?.description ?? "Login failed");
      }
    } catch (e) {
      // 6. 捕获底层异常（如网络异常、存储异常），向上抛出由上层处理
      // 不在这里吞异常，保证异常可追溯，上层可统一处理（如弹窗提示）
      rethrow;
    }
  }

  /// 注册业务方法（实现接口定义）
  /// 核心流程：参数封装 → 调用注册 API → 校验响应 → 无返回值（注册成功仅需确认状态）
  /// 参数：
  ///   - email：注册邮箱
  ///   - password：注册密码
  ///   - nickname：用户昵称
  /// 异常：抛出 Exception，包含具体错误描述
  @override
  Future<void> register(
      String email, String password, String nickname, String? avatarUrl) async {
    try {
      // 1. 封装注册请求参数
      final response = await _api.register(RegisterRequest(
          email: email,
          password: password,
          nickname: nickname,
          avatarUrl: avatarUrl));

      // 2. 校验注册响应是否成功，失败则抛异常
      if (!response.isSuccess) {
        throw Exception(response.error?.description ?? "Register failed");
      }
      // 3. 注册成功无需返回数据，仅需正常结束 Future
    } catch (e) {
      // 捕获底层异常并向上抛出
      rethrow;
    }
  }

  /// 登出业务方法（实现接口定义）
  /// 核心逻辑：清理本地存储的 Token（无需调用后端接口，前端登出核心是销毁 Token）
  /// 说明：若后端需要「登出接口」（如失效 Token），可在此处添加 _api.logout() 调用
  @override
  Future<void> logout() async {
    // 清理本地 Token，使后续接口请求失去鉴权能力，达到登出效果
    await _tokenStorage.clearTokens();
  }

  /// 检查是否已登录（实现接口定义）
  /// 核心逻辑：通过判断本地是否存在有效的 AccessToken，确定登录状态
  /// 返回值：bool - true（已登录）/ false（未登录）
  @override
  Future<bool> isLoggedIn() async {
    // 1. 从本地存储获取 AccessToken
    final token = await _tokenStorage.getAccessToken();
    // 2. 校验 Token 是否存在且非空（空 Token 视为未登录）
    return token != null && token.isNotEmpty;
  }
}
