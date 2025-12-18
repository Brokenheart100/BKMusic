import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// --- 页面引入 ---
// 登录页面：用户认证入口
import 'package:music_app/features/auth/presentation/pages/login_page.dart';
// 首页：应用核心功能展示页
import 'package:music_app/features/home/presentation/pages/home_screen.dart';
// 资料库：用户音乐收藏/本地音乐管理页
import 'package:music_app/features/library/presentation/pages/library_screen.dart';
// 播放页：全屏音乐播放控制页
import 'package:music_app/features/music_player/presentation/pages/player_screen.dart';
// 搜索页：音乐搜索功能页
import 'package:music_app/features/search/presentation/pages/search_screen.dart';
// 主布局包装器：包含底部导航栏/侧边栏的通用布局
import 'package:music_app/main_wrapper.dart';

// --- 状态与监听器引入 ---
// 认证状态Provider：存储用户登录/登出状态
import 'package:music_app/features/auth/presentation/providers/auth_provider.dart';
// 认证状态监听器：用于GoRouter监听登录状态变化，触发路由重定向
import 'package:music_app/core/router/auth_listenable.dart';

/// 路由路径常量类
/// 作用：
/// 1. 统一管理所有路由路径，避免硬编码导致的拼写错误
/// 2. 便于后期路由路径修改（只需改此处，无需全局替换）
/// 3. 提高代码可读性，语义化命名
class Routes {
  // 首页路由（根路径）
  static const String home = '/';
  // 资料库路由
  static const String library = '/library';
  // 全屏播放页路由
  static const String player = '/player';
  // 搜索页路由
  static const String search = '/search';
  // 登录页路由
  static const String login = '/login';
}

// 导航器Key：用于区分不同层级的Navigator，解决嵌套导航问题
// 1. 根导航器Key：控制整个App的顶级导航（如登录页、全屏播放页）
final _rootNavigatorKey = GlobalKey<NavigatorState>();
// 2. Shell导航器Key：控制ShellRoute内部的导航（如首页、资料库）
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter 实例的Provider
/// 设计思路：
/// - 使用Riverpod的Provider包装GoRouter，而非全局变量
/// - 可以通过ref读取/监听Riverpod的状态（如登录状态）
/// - 实现响应式路由管理（登录状态变化自动触发路由重定向）
final goRouterProvider = Provider<GoRouter>((ref) {
  // 获取认证状态监听器：封装了对authStateProvider的监听
  // 当登录状态变化时，会通知GoRouter触发refresh（重新执行redirect逻辑）
  final authListenable = ref.watch(authListenableProvider);

  // 构建GoRouter核心实例
  return GoRouter(
    // 设置根导航器Key：所有未指定parentNavigatorKey的路由使用此导航器
    navigatorKey: _rootNavigatorKey,
    // 初始路由：App启动时默认跳转的路径
    initialLocation: Routes.home,

    // 【核心功能1：响应式刷新触发】
    // 监听authListenable的状态变化，当登录状态改变时：
    // 1. GoRouter会自动调用redirect方法
    // 2. 实现"登录后自动跳首页、登出后自动跳登录页"的效果
    refreshListenable: authListenable,

    // 【核心功能2：路由守卫（重定向逻辑）】
    // 每次路由跳转前都会执行此方法，返回：
    // - null：放行，跳转到目标路由
    // - 非null字符串：强制跳转到指定路由
    redirect: (context, state) {
      // 1. 读取当前登录状态（从Riverpod的authStateProvider获取）
      final isLoggedIn = ref.read(authStateProvider);

      // 2. 判断当前要跳转的目标是否是登录页
      final isGoingToLogin = state.matchedLocation == Routes.login;

      // 3. 核心逻辑判断
      if (!isLoggedIn) {
        // 未登录状态：
        // - 如果目标是登录页 → 放行（允许进入登录页）
        // - 如果目标不是登录页 → 强制跳转到登录页（拦截未登录访问）
        return isGoingToLogin ? null : Routes.login;
      } else {
        // 已登录状态：
        // - 如果目标是登录页 → 强制跳转到首页（避免已登录用户访问登录页）
        if (isGoingToLogin) {
          return Routes.home;
        }
      }

      // 其他情况（已登录且访问非登录页）→ 放行
      return null;
    },

    // 【路由配置表】：按业务逻辑分层管理路由
    routes: [
      // 1. 登录页路由（独立路由，无Shell布局）
      // 特点：不包含底部导航栏/侧边栏，是纯登录界面
      GoRoute(
        path: Routes.login, // 路由路径
        // 页面构建器：返回登录页组件
        builder: (context, state) => const LoginPage(),
      ),

      // 2. ShellRoute（壳路由）：带通用布局的嵌套路由
      // 设计思路：
      // - 封装通用布局（MainWrapper包含底部导航栏/侧边栏）
      // - 子路由（首页、资料库）会作为child传入MainWrapper
      // - 切换子路由时，MainWrapper不会重建，仅替换child部分
      ShellRoute(
        // 指定Shell内部的导航器Key
        navigatorKey: _shellNavigatorKey,
        // Shell构建器：包裹子路由的通用布局
        builder: (context, state, child) {
          // MainWrapper：包含底部导航栏的布局组件，child是当前激活的子路由页面
          return MainWrapper(child: child);
        },
        // Shell的子路由（共享MainWrapper布局）
        routes: [
          // 首页路由（Shell内部）
          GoRoute(
            path: Routes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          // 资料库路由（Shell内部）
          GoRoute(
            path: Routes.library,
            builder: (context, state) => const LibraryScreen(),
          ),
        ],
      ),

      // 3. 搜索页路由（全屏路由，独立动画）
      // 特点：
      // - 使用rootNavigatorKey：覆盖整个屏幕，不显示Shell的底部导航栏
      // - 自定义转场动画：淡入淡出效果
      GoRoute(
        // 指定父导航器为根导航器（全屏显示）
        parentNavigatorKey: _rootNavigatorKey,
        path: Routes.search,
        // pageBuilder：自定义页面转场动画（区别于普通builder）
        pageBuilder: (context, state) => CustomTransitionPage(
          // 页面唯一标识：确保动画和路由状态正确关联
          key: state.pageKey,
          // 搜索页组件
          child: const SearchScreen(),
          // 转场动画构建器：淡入淡出效果
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              // animation：入场动画（0→1），控制透明度
              opacity: animation,
              child: child,
            );
          },
        ),
      ),

      // 4. 全屏播放页路由（全屏路由，自定义滑出动画）
      // 特点：
      // - 使用rootNavigatorKey：覆盖整个屏幕
      // - 自定义转场动画：从底部向上滑出，符合音乐播放页的交互习惯
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: Routes.player,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PlayerScreen(),
          // 转场动画构建器：从下往上滑出
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 动画起始位置：屏幕底部（y轴1.0）
            const begin = Offset(0.0, 1.0);
            // 动画结束位置：屏幕正常位置（原点）
            const end = Offset.zero;
            // 动画曲线：缓出 Quart 曲线，让滑动更自然
            const curve = Curves.easeOutQuart;

            // 组合动画：先应用曲线，再应用位移动画
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            // 滑动转场：使用animation驱动tween，实现从下往上滑出
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
    ],
  );
});
