import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/router/app_router.dart';
import 'package:music_app/features/auth/presentation/providers/auth_provider.dart';

// 1. 这是 App 的入口 Widget，包含 MaterialApp 配置
class MusicApp extends ConsumerStatefulWidget {
  const MusicApp({super.key});

  @override
  ConsumerState<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends ConsumerState<MusicApp> {
  @override
  void initState() {
    super.initState();
    ref.read(authControllerProvider).checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Enterprise Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark, // 音乐 App 通常是暗色模式
        ),
      ),
      routerConfig: router, // 使用 GoRouter 管理路由
    );
  }
}
