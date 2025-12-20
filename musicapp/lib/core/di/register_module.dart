import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:music_app/core/db/objectbox_manager.dart';
import 'package:music_app/core/network/dio_interceptor.dart'; // 【新增】引入拦截器
import 'package:music_app/core/services/audio_handler.dart';
import 'package:music_app/features/auth/data/datasources/auth_api.dart';
import 'package:music_app/features/favorites/data/datasources/favorites_api.dart';
import 'package:music_app/features/home/data/datasources/music_api.dart';
import 'package:music_app/features/library/data/datasources/playlist_api.dart';
import 'package:music_app/features/music_player/data/datasources/media_api.dart';
import 'package:music_app/features/search/data/datasources/search_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class RegisterModule {
  @singleton
  Logger get logger => Logger(
        filter: kReleaseMode ? ProductionFilter() : DevelopmentFilter(),
        printer: PrettyPrinter(
          methodCount: kReleaseMode ? 0 : 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: !kReleaseMode,
          printEmojis: true,
        ),
        output: ConsoleOutput(),
      );

  // 【核心修改】改为方法，接收 AuthInterceptor 参数
  @singleton
  Dio dio(AuthInterceptor authInterceptor) {
    // 临时 Logger 用于打印初始化日志
    final log = Logger(printer: PrettyPrinter(methodCount: 0));
    log.d("🛠️ [Dio] 开始构建网络客户端...");

    // 1. 动态判断 Gateway 地址
    const gatewayPort = '7101';
    String baseUrl;

    if (kIsWeb) {
      baseUrl = 'https://localhost:$gatewayPort/api';
      log.i("🌍 [Dio] 检测到 Web 环境，BaseURL: $baseUrl");
    } else if (!kIsWeb && Platform.isAndroid) {
      baseUrl = 'https://10.0.2.2:$gatewayPort/api';
      log.i("🤖 [Dio] 检测到 Android 环境，使用宿主 IP: $baseUrl");
    } else {
      baseUrl = 'https://localhost:$gatewayPort/api';
      log.i("💻 [Dio] 检测到 桌面/iOS 环境，BaseURL: $baseUrl");
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 2. SSL 证书绕过 (仅开发环境)
    if (!kIsWeb) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
      log.w("🔓 [Dio] 开发环境：已禁用 SSL 证书验证");
    }

    // 3. 【核心】添加 AuthInterceptor
    // 必须加在日志拦截器之前，这样日志才能打印出 Authorization 头
    dio.interceptors.add(authInterceptor);
    log.i("🛡️ [Dio] AuthInterceptor 已注入");

    // 4. 添加 Emoji 日志拦截器
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        log.i("🚀 📤 [REQUEST] ${options.method} ${options.uri}\n"
            "📦 Headers: ${options.headers}\n"
            "📝 Data: ${options.data ?? 'None'}");
        return handler.next(options);
      },
      onResponse: (response, handler) {
        log.d(
            "💎 📥 [RESPONSE] [${response.statusCode}] ${response.requestOptions.uri}\n"
            "📦 Data: ${response.data}");
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        log.e(
            "🔥 💀 [ERROR] [${e.response?.statusCode}] ${e.requestOptions.uri}\n"
            "❌ Type: ${e.type}\n"
            "📄 Message: ${e.message}\n"
            "🐛 Response: ${e.response?.data}");
        return handler.next(e);
      },
    ));

    log.d("✅ [Dio] 网络客户端构建完成！");
    return dio;
  }

  @singleton
  FavoritesApi favoritesApi(Dio dio) => FavoritesApi(dio);

  @singleton
  AuthApi authApi(Dio dio) => AuthApi(dio);

  @singleton
  SearchApi searchApi(Dio dio) => SearchApi(dio);

  @singleton
  PlaylistApi playlistApi(Dio dio) => PlaylistApi(dio);

  @singleton
  MediaApi mediaApi(Dio dio) => MediaApi(dio);

  @singleton
  MusicApi musicApi(Dio dio) => MusicApi(dio);

  @singleton
  @preResolve
  Future<SharedPreferences> get prefs async {
    final prefs = await SharedPreferences.getInstance();
    return prefs;
  }

  @singleton
  @preResolve
  Future<MusicHandler> get musicHandler async {
    final log = Logger(printer: PrettyPrinter(methodCount: 0));
    log.d("🎧 [Audio] 正在启动音频后台服务...");

    final handler = await AudioService.init(
      builder: () => MusicHandlerImpl(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.company.music_app.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
      ),
    );

    log.i("✅ [Audio] 音频服务启动就绪！");
    return handler;
  }

  @singleton
  @preResolve
  Future<ObjectBoxManager> get objectBoxManager => ObjectBoxManager.create();
}
