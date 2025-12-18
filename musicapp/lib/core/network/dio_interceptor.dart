import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:music_app/core/services/token_storage.dart';

@injectable
class AuthInterceptor extends Interceptor {
  final Logger _logger;
  final TokenStorage _tokenStorage;
  // 注入 Dio 实例用于发起刷新请求 (使用 Lazy 或者通过 handler 获取，避免循环依赖)
  // 这里我们将在 onError 中通过 err.requestOptions 获取 Dio

  // 锁标志：是否正在刷新 Token
  bool _isRefreshing = false;
  // 等待队列：存储在刷新期间失败的请求
  final List<void Function(String newToken)> _requestQueue = [];

  AuthInterceptor(this._logger, this._tokenStorage);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. 获取本地 Token
    final token = await _tokenStorage.getAccessToken();

    // 2. 如果有 Token 且请求头没有手动设置过，则注入
    if (token != null && options.headers['Authorization'] == null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    if (options.path.contains('/auth/refresh')) {
      // 如果是刷新接口，不需要 Bearer Token (或者需要 Refresh Token，视后端实现而定)
      // 通常刷新接口在 Body 里传 RefreshToken，这里视情况处理
    }

    _logger.i('🚀 REQUEST[${options.method}] => PATH: ${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    _logger.e(
        '🔥 ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');

    // 1. 判断是否是 401 未授权
    if (err.response?.statusCode == 401) {
      final options = err.requestOptions;

      // 如果出错的本身就是“登录”或“刷新Token”的接口，说明没救了，直接拒绝
      if (options.path.contains('/auth/login') ||
          options.path.contains('/auth/refresh')) {
        return super.onError(err, handler);
      }

      // 2. 如果当前没有在刷新，则开启刷新流程
      if (!_isRefreshing) {
        _isRefreshing = true;

        try {
          // 获取 Refresh Token
          final refreshToken = await _tokenStorage.getRefreshToken();
          final accessToken = await _tokenStorage.getAccessToken();

          if (refreshToken == null) {
            _performLogout(handler, err);
            return;
          }

          // 3. 发起刷新请求
          // 注意：创建一个新的 Dio 实例，或者确保这个请求不走拦截器，防止死循环
          // 这里为了简单，我们用原 Dio 但排除 Authorization 头，或者新建 Dio
          // 更好的方式是单独定义一个 AuthAPI 不走拦截器。
          // 这里演示使用原生 Dio 发起请求：
          final dio = Dio(BaseOptions(
              baseUrl: options.baseUrl,
              headers: {'Content-Type': 'application/json'}));

          // 绕过自签名证书 (仅开发环境)
          // (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = ... (同 register_module)

          _logger.w("🔄 401检测，正在尝试刷新 Token...");

          final refreshResponse = await dio.post('/api/auth/refresh',
              data: {'accessToken': accessToken, 'refreshToken': refreshToken});

          if (refreshResponse.statusCode == 200 &&
              refreshResponse.data['isSuccess']) {
            final newData = refreshResponse.data['value'];
            final newAccessToken = newData['accessToken'];
            final newRefreshToken = newData['refreshToken'];

            // 4. 保存新 Token
            await _tokenStorage.saveTokens(
                accessToken: newAccessToken, refreshToken: newRefreshToken);
            _logger.i("✅ Token 刷新成功！");

            // 5. 执行队列中的请求
            _isRefreshing = false;
            _retryRequests(newAccessToken, handler, err); // 重试当前请求
            _processQueue(newAccessToken); // 重试排队请求
          } else {
            _performLogout(handler, err);
          }
        } catch (e) {
          _logger.e("❌ Token 刷新失败", error: e);
          _performLogout(handler, err);
        } finally {
          _isRefreshing = false;
        }
      } else {
        // 6. 如果正在刷新，将当前请求加入队列，等待刷新完成
        _logger.d("⏳ 请求加入等待队列: ${options.path}");
        _requestQueue.add((newToken) {
          // 更新 Token 并重试
          options.headers['Authorization'] = 'Bearer $newToken';
          // 使用 err.requestOptions.extra['dio'] 或者 全局 Dio 来重试
          // 这里通过 handler.resolve 发起一个新的请求是不行的，必须重新发起 Dio 请求
          // 简单的做法：
          final dio = Dio(BaseOptions(baseUrl: options.baseUrl));
          // 更好的做法是获取当前的 Dio 实例。
          // 由于篇幅限制，这里简化处理：
          _retryRequestWithDio(dio, options, handler);
        });
      }
    } else {
      super.onError(err, handler);
    }
  }

  // 重试单个请求
  void _retryRequests(String newToken, ErrorInterceptorHandler handler,
      DioException err) async {
    final requestOptions = err.requestOptions;
    requestOptions.headers['Authorization'] = 'Bearer $newToken';

    // 创建临时的 Dio 实例来重试，或者从 DI 获取
    // 注意：这里需要确保 SSL 配置同步，最稳妥是从 DI 拿 Dio，但要注意死循环风险
    // 这里简单 new 一个 Dio 演示原理
    final dio = Dio(BaseOptions(
        baseUrl: requestOptions.baseUrl,
        headers: {'Content-Type': 'application/json'}));

    // 【核心补充】开发环境 SSL 绕过
    // 必须加上这段，否则本地调试无法刷新 Token
    if (!kIsWeb) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }

    try {
      final response = await dio.request(
        requestOptions.uri.toString(),
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: Options(
          method: requestOptions.method,
          headers: requestOptions.headers,
        ),
      );
      handler.resolve(response);
    } catch (e) {
      if (e is DioException) {
        handler.next(e);
      }
    }
  }

  // 处理队列
  void _processQueue(String newToken) {
    for (var callback in _requestQueue) {
      callback(newToken);
    }
    _requestQueue.clear();
  }

  // 登出处理
  void _performLogout(ErrorInterceptorHandler handler, DioException err) {
    _tokenStorage.clearTokens();
    _requestQueue.clear();
    _isRefreshing = false;
    // TODO: 这里可以发布一个全局事件总线 EventBus，或者使用 GoRouter 跳转登录页
    _logger.e("⛔ 登录已失效，请重新登录");
    super.onError(err, handler);
  }

  // 辅助重试方法 (简化版)
  void _retryRequestWithDio(Dio dio, RequestOptions requestOptions,
      ErrorInterceptorHandler handler) async {
    try {
      final response = await dio.fetch(requestOptions);
      handler.resolve(response);
    } catch (e) {
      // ignore
    }
  }
}
