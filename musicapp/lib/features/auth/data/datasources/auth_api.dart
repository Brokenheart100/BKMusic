import 'package:dio/dio.dart';
import 'package:music_app/core/network/api_response.dart';
import 'package:music_app/features/auth/data/models/auth_dto.dart';
import 'package:retrofit/retrofit.dart';

/// 生成代码的关联文件声明
/// 说明：
/// 1. 该文件由 Retrofit 代码生成工具自动生成（通过 build_runner 命令）
/// 2. 生成命令：flutter pub run build_runner build/watch
/// 3. 手动修改此文件无效，需修改当前接口后重新生成
part 'auth_api.g.dart';

/// 认证模块 API 接口定义（基于 Retrofit 封装）
/// 设计思路：
/// - 使用 Retrofit 注解化定义 RESTful API，替代手写 Dio 请求
/// - 统一接收 Dio 实例，便于全局配置（如基础URL、拦截器、超时时间）
/// - 返回值封装为通用 ApiResponse 模型，统一处理接口响应格式
@RestApi() // Retrofit 核心注解：标记此类为 REST API 接口，用于生成实现类
abstract class AuthApi {
  /// 工厂方法：创建 AuthApi 实现类实例
  /// 参数：dio - 预配置的 Dio 实例（全局单例，包含基础URL、拦截器等）
  /// 说明：Retrofit 生成的 _AuthApi 类会实现此工厂方法，封装 Dio 调用逻辑
  factory AuthApi(Dio dio) = _AuthApi;

  /// 登录接口
  /// 请求方式：POST
  /// 请求路径：/auth/login
  /// 参数说明：
  ///   @Body() - 将 LoginRequest 对象序列化为 JSON 作为请求体
  ///   request - 登录请求参数（包含用户名/手机号、密码等）
  /// 返回值：ApiResponse<AuthResponse>
  ///   - ApiResponse：全局通用响应包装类（包含 code/message/data 等字段）
  ///   - AuthResponse：登录成功后的响应数据（包含 token、用户信息等）
  @POST("/auth/login")
  Future<ApiResponse<AuthResponse>> login(@Body() LoginRequest request);

  /// 注册接口
  /// 请求方式：POST
  /// 请求路径：/auth/register
  /// 参数说明：
  ///   @Body() - 将 RegisterRequest 对象序列化为 JSON 作为请求体
  ///   request - 注册请求参数（包含用户名、密码、手机号、验证码等）
  /// 返回值：ApiResponse<void>
  ///   - void 表示接口返回数据无业务实体（仅需判断是否成功）
  ///   - ApiResponse 仍包含 code/message 用于判断注册结果
  @POST("/auth/register")
  Future<ApiResponse<void>> register(@Body() RegisterRequest request);
}
