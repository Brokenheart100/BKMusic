import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// --- 页面引入 ---
import 'package:music_app/features/auth/presentation/pages/login_page.dart';
import 'package:music_app/features/home/presentation/pages/home_screen.dart';
import 'package:music_app/features/library/presentation/pages/library_screen.dart';
import 'package:music_app/features/library/presentation/pages/playlist_detail_screen.dart';
import 'package:music_app/features/music_player/presentation/pages/player_screen.dart';
import 'package:music_app/features/search/presentation/pages/search_screen.dart';
// 【新增】引入收藏页
import 'package:music_app/features/favorites/presentation/pages/favorites_screen.dart';
import 'package:music_app/main_wrapper.dart';

import 'package:music_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:music_app/core/router/auth_listenable.dart';

class Routes {
  static const String home = '/';
  static const String library = '/library';
  static const String player = '/player';
  static const String search = '/search';
  static const String login = '/login';
  static const String favorites = '/favorites';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = ref.watch(authListenableProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.home,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authStateProvider);
      final isGoingToLogin = state.matchedLocation == Routes.login;

      if (!isLoggedIn) {
        return isGoingToLogin ? null : Routes.login;
      } else {
        if (isGoingToLogin) {
          return Routes.home;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainWrapper(child: child);
        },
        routes: [
          GoRoute(
            path: Routes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: Routes.library,
            builder: (context, state) => const LibraryScreen(),
          ),
          GoRoute(
            path: Routes.favorites,
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/playlists/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return CustomTransitionPage(
                key: state.pageKey,
                child: PlaylistDetailScreen(playlistId: id),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  // 在内容区内部，使用"渐隐渐显"比"滑入"更自然，像网页切换
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              );
            },
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: Routes.search,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SearchScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: Routes.player,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PlayerScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutQuart;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
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
