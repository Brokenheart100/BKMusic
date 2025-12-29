import 'dart:ui'; // 提供 ImageFilter（毛玻璃效果）、Window 相关API
import 'package:flutter/material.dart'; // Flutter核心UI组件库
import 'package:flutter/services.dart'; // 提供键盘快捷键、系统交互相关API
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod状态管理（消费/读写状态）
import 'package:go_router/go_router.dart'; // GoRouter路由跳转（菜单点击跳转页面）
import 'package:music_app/core/router/app_router.dart'; // 自定义路由常量（如Routes.home）
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart'; // 播放器状态管理（播放/暂停控制）
import 'package:music_app/features/music_player/presentation/widgets/mini_player.dart'; // 迷你播放器组件（底部通栏播放条）

/// 应用全局主布局容器
/// 核心作用：
/// 1. 统一包裹所有页面，提供固定布局结构（侧边栏 + 路由内容区 + 底部迷你播放器）；
/// 2. 处理全局交互（键盘快捷键、侧边栏菜单跳转）；
/// 3. 适配主题、布局层级，保证迷你播放器浮在最上层；
class MainWrapper extends ConsumerStatefulWidget {
  // 子组件：GoRouter匹配到的当前路由页面（如Discover/Trending/Library页）
  final Widget child;
  const MainWrapper({super.key, required this.child});

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  // 侧边栏菜单选中索引（控制菜单高亮、路由跳转）
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 读取播放器控制器（用于空格键播放/暂停快捷键）
    final controller = ref.read(playerControllerProvider);
    // 获取当前主题（适配颜色、样式，保证深色/浅色模式统一）
    final theme = Theme.of(context);

    // 固定迷你播放器高度（全局统一，避免布局抖动）
    const double playerHeight = 80;

    // 全局键盘快捷键绑定（空格键控制播放/暂停）
    return CallbackShortcuts(
      // 快捷键映射：空格键 → 触发播放器播放/暂停切换
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () =>
            controller.togglePlay(),
      },
      // 焦点控制：让Scaffold获取焦点，确保快捷键生效
      child: Focus(
        autofocus: true,
        child: Scaffold(
          // 适配主题背景色（深色/浅色模式）
          backgroundColor: theme.scaffoldBackgroundColor,
          // 【核心修改 1】将Stack提到最外层，占据整个Body
          // 布局逻辑：Stack实现“层级覆盖”——主体内容在下层，迷你播放器浮在底部上层
          body: Stack(
            children: [
              // --- 层级 A：页面主体内容 (侧边栏 + 路由页) ---
              Row(
                children: [
                  // 1. 侧边栏（固定宽度240，全局导航区）
                  Container(
                    width: 240, // 侧边栏固定宽度，适配桌面端体验
                    color: Colors.transparent, // 透明背景，继承Scaffold的主题色
                    child: Column(
                      children: [
                        // 顶部留白（视觉呼吸感）
                        const SizedBox(height: 32),
                        // 窗口标题栏占位（桌面端窗口标题栏与App内标题区对齐）
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              // App图标（音乐符号，适配主题主色）
                              Icon(Icons.music_note_rounded,
                                  size: 32, color: theme.primaryColor),
                              const SizedBox(width: 12),
                              // App名称（加粗、字母间距优化，增强视觉识别）
                              const Text("Musica",
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 菜单区域（可滚动，适配更多菜单项）
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // 构建侧边栏菜单项：Discover（发现页）
                                _buildMenuItem(
                                    0, Icons.compass_calibration, "Discover"),
                                // 构建侧边栏菜单项：Trending（热门页）
                                _buildMenuItem(
                                    1, Icons.trending_up, "Trending"),
                                // 构建侧边栏菜单项：Library（音乐库）
                                _buildMenuItem(
                                    2, Icons.library_music, "Library"),
                                // 构建侧边栏菜单项：Favorites（收藏页）
                                _buildMenuItem(
                                    3, Icons.favorite_border, "Favorites"),
                              ],
                            ),
                          ),
                        ),

                        // 退出登录按钮（侧边栏底部）
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 24, left: 16, right: 16),
                          child: InkWell(
                            // 点击事件：退出登录（暂时注释，可按需启用）
                            onTap: () {
                              // ref.read(authControllerProvider).logout();
                            },
                            // 圆角点击反馈（Material设计规范）
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              // 边框样式：半透明白色边框，增强层次感
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  // 退出图标（红色强调，提示危险操作）
                                  const Icon(Icons.logout_rounded,
                                      color: Colors.redAccent, size: 20),
                                  const SizedBox(width: 12),
                                  // 退出文字（红色、加粗，强化视觉提示）
                                  const Text("Log Out",
                                      style: TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 【核心修改 2】给侧边栏底部留白
                        // 原因：避免侧边栏底部内容（如退出按钮）被底部迷你播放器遮挡
                        const SizedBox(height: playerHeight),
                      ],
                    ),
                  ),

                  // 2. 路由页面内容区（占满剩余宽度）
                  Expanded(
                    child: Padding(
                      // 内容区底部留白：与侧边栏留白对应，防止页面内容被迷你播放器遮挡
                      padding: const EdgeInsets.only(bottom: playerHeight),
                      // 显示当前路由匹配的页面（如Discover页、Library页）
                      child: widget.child,
                    ),
                  ),
                ],
              ),

              // --- 层级 B：全宽 MiniPlayer (浮在最上面) ---
              Positioned(
                left: 0, // 贴左边屏幕边缘（覆盖侧边栏，实现通栏效果）
                right: 0, // 贴右边屏幕边缘
                bottom: 0, // 贴底部
                height: playerHeight, // 固定高度，与上方留白一致
                child: Stack(
                  // 允许子组件（如进度条圆点）溢出容器（避免裁剪交互元素）
                  clipBehavior: Clip.none,
                  children: [
                    // 背景毛玻璃效果（增强视觉层级，区分播放器与页面内容）
                    Positioned.fill(
                      child: ClipRect(
                        // 限制毛玻璃效果范围，避免溢出
                        child: BackdropFilter(
                          // 高斯模糊：X/Y方向各30，营造毛玻璃质感
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Container(
                            decoration: BoxDecoration(
                              // 半透明黑色背景：增强毛玻璃对比度，保证文字可见
                              color: Colors.black.withValues(alpha: 0.85),
                              // 顶部细边框：分隔播放器与页面内容，增强边界感
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 播放器核心内容（MiniPlayer组件）
                    const Positioned.fill(
                      child: SafeArea(
                        top: false, // 底部不需要SafeArea（避免额外留白）
                        child: MiniPlayer(), // 引入迷你播放器组件
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建侧边栏菜单项
  /// 参数：
  ///   - index：菜单项索引（匹配_selectedIndex，控制选中状态）
  ///   - icon：菜单项图标
  ///   - label：菜单项文字
  Widget _buildMenuItem(int index, IconData icon, String label) {
    // 判断当前菜单项是否选中（控制高亮样式）
    final isSelected = _selectedIndex == index;
    // 获取主题色（适配选中/未选中状态的颜色）
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      // 点击事件：更新选中索引 + 跳转对应路由
      onTap: () {
        setState(() => _selectedIndex = index); // 更新选中状态（UI高亮）
        // 根据索引跳转对应路由
        switch (index) {
          case 0:
            context.go(Routes.home); // 0 → Discover（首页/发现页）
            break;
          case 2:
            context.go(Routes.library); // 2 → Library（音乐库）
            break;
          case 3:
            context.go(Routes.favorites); // 3 → Favorites（收藏页）
            break;
          // case 1: 暂未配置Trending路由，可按需补充
        }
      },
      child: Container(
        // 边距：水平16，垂直4 → 控制菜单项间距，增强呼吸感
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        // 内边距：水平16，垂直12 → 控制菜单项大小，保证点击区域足够
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        // 背景样式：选中时用主题主色半透明背景，未选中时透明
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12), // 圆角样式，符合Material设计
        ),
        child: Row(
          children: [
            // 菜单项图标：选中时用主题主色，未选中时用半透明白色
            Icon(icon,
                color: isSelected ? colorScheme.primary : Colors.white54,
                size: 22),
            const SizedBox(width: 16), // 图标与文字间距
            // 菜单项文字：选中时白色+加粗，未选中时半透明白色+常规字重
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14, // 适配桌面端阅读体验
              ),
            ),
          ],
        ),
      ),
    );
  }
}
