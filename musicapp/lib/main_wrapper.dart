import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/core/router/app_router.dart';
import 'package:music_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';
import 'package:music_app/features/music_player/presentation/widgets/mini_player.dart';

class MainWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const MainWrapper({super.key, required this.child});

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // 【核心】加载收藏 ID 列表
    // 使用 addPostFrameCallback 确保在构建完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favoriteIdsProvider.notifier).loadIds();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(playerControllerProvider);
    final theme = Theme.of(context);

    // 播放条高度常量，用于计算 Padding
    const double playerHeight = 80;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () =>
            controller.togglePlay(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          // 【核心修改】Stack 提到最外层，让播放条浮在所有内容之上
          body: Stack(
            children: [
              // --- 底层：侧边栏 + 页面内容 ---
              Row(
                children: [
                  // 1. 侧边栏
                  Container(
                    width: 240,
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        // 窗口标题栏占位 (如果用了 WindowManager)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              Icon(Icons.music_note_rounded,
                                  size: 32, color: theme.primaryColor),
                              const SizedBox(width: 12),
                              const Text("Musica",
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 菜单区域
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildMenuItem(
                                    0, Icons.compass_calibration, "Discover"),
                                _buildMenuItem(
                                    1, Icons.trending_up, "Trending"),
                                _buildMenuItem(
                                    2, Icons.library_music, "Library"),
                                _buildMenuItem(
                                    3, Icons.favorite_border, "Favorites"),
                              ],
                            ),
                          ),
                        ),

                        // 【新增】底部留白，防止被通栏播放器挡住
                        const SizedBox(height: playerHeight),
                      ],
                    ),
                  ),

                  // 2. 页面内容区
                  Expanded(
                    child: Padding(
                      // 【新增】底部留白，防止被通栏播放器挡住
                      padding: const EdgeInsets.only(bottom: playerHeight),
                      child: widget.child,
                    ),
                  ),
                ],
              ),

              // --- 顶层：全宽 MiniPlayer ---
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: playerHeight, // 固定高度
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.6),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: const SafeArea(
                        top: false,
                        child: MiniPlayer(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);

        // 【核心修复：添加跳转逻辑】
        switch (index) {
          case 0:
            context.go(Routes.home);
            break;
          case 1:
            // 对应 Discover / Trending，暂时也可以指向 Home 或开发中页面
            // context.go(Routes.trending);
            break;
          case 2:
            context.go(Routes.library);
            break;
          case 3:
            context.go(Routes.favorites);
            break;
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? colorScheme.primary : Colors.white54,
                size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
