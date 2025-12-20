import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:music_app/core/di/injection.config.dart';
import 'package:music_app/core/network/dio_interceptor.dart'; // 引入 AuthInterceptor

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  // 1. 初始化所有依赖 (包括 Dio 和 AuthInterceptor)
  await getIt.init();

  final dio = getIt<Dio>();
  final authInterceptor = getIt<AuthInterceptor>();
  final logger = getIt<Logger>(); // 获取 Logger
  // 确保不重复添加 (防止热重载导致重复)
  // 1. 先添加 AuthInterceptor (注入 Token)
  if (!dio.interceptors.contains(authInterceptor)) {
    // 【关键】要把 AuthInterceptor 加到最前面，确保它先执行
    dio.interceptors.insert(0, authInterceptor);
  }

  // 2. 后添加 日志拦截器 (这样它打印的就是注入 Token 后的 Header)
  // 我们可以复用你之前写的那个漂亮的 Emoji 日志逻辑，或者简单用 LogInterceptor
  // 这里为了方便展示，添加一个匿名拦截器
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      logger.i(
          "💡 🚀 📤 [REQUEST] ${options.method} ${options.uri}\nHeaders: ${options.headers}");
      handler.next(options);
    },
    onResponse: (response, handler) {
      logger.d("💡 💎 📥 [RESPONSE] [${response.statusCode}]");
      handler.next(response);
    },
    onError: (DioException e, handler) {
      logger.e("💡 ⛔ 💀 [ERROR] [${e.response?.statusCode}]");
      handler.next(e);
    },
  ));
}
