import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:logger/logger.dart'; // 1. 引入 Logger
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:music_app/features/home/domain/entities/song.dart';

// 1. 收藏 ID 集合 Provider (用于快速判断是否红心)
final favoriteIdsProvider =
    StateNotifierProvider<FavoriteIdsNotifier, Set<String>>((ref) {
  return FavoriteIdsNotifier();
});

class FavoriteIdsNotifier extends StateNotifier<Set<String>> {
  FavoriteIdsNotifier() : super({});

  final _repository = getIt<FavoritesRepository>();
  // 2. 注入 Logger
  final Logger _logger = getIt<Logger>();

  // 初始化：加载所有收藏ID
  Future<void> loadIds() async {
    _logger.d("🔍 [Fav] 正在从后端拉取收藏 ID 列表...");
    try {
      final ids = await _repository.getFavoriteIds();
      state = ids;
      _logger.i("✅ [Fav] ID 列表加载完毕，共 ${ids.length} 首收藏");
    } catch (e, stack) {
      _logger.e("❌ [Fav] 加载 ID 列表失败", error: e, stackTrace: stack);
    }
  }

  // 核心：切换状态 (乐观更新)
  Future<void> toggle(String songId) async {
    final isCurrentlyLiked = state.contains(songId);
    final action = isCurrentlyLiked ? "取消收藏" : "添加收藏";

    // 1. 乐观更新：立即修改 UI
    if (isCurrentlyLiked) {
      state = {...state}..remove(songId);
    } else {
      state = {...state}..add(songId);
    }

    // 打印乐观更新日志
    _logger.i("❤️ [Fav] 触发操作: $action (ID: $songId) - UI已先行更新");

    try {
      // 2. 发送网络请求
      final serverState = await _repository.toggleFavorite(songId);
      _logger.d("🔙 [Fav] 后端返回最新状态: $serverState");

      // 3. (可选) 校准：如果后端返回的状态和乐观更新的不一致，修正回来
      if (serverState != !isCurrentlyLiked) {
        _logger.w(
            "⚠️ [Fav] 状态不一致 (前端:${!isCurrentlyLiked} vs 后端:$serverState)，正在修正...");

        if (serverState) {
          state = {...state}..add(songId);
        } else {
          state = {...state}..remove(songId);
        }
      }
    } catch (e, stack) {
      // 4. 回滚：如果网络失败，恢复原状
      _logger.e("❌ [Fav] 网络请求失败，正在回滚状态...", error: e, stackTrace: stack);

      if (isCurrentlyLiked) {
        state = {...state}..add(songId); // 恢复添加
      } else {
        state = {...state}..remove(songId); // 恢复删除
      }
      rethrow; // 让 UI 能够捕获并提示错误
    }
  }
}

// 2. 收藏歌曲列表 Provider (用于 Favorites 页面展示)
final favoriteSongsProvider =
    FutureProvider.autoDispose<List<Song>>((ref) async {
  // 获取 Logger (Provider 内部无法直接访问类成员，需单独获取)
  final logger = getIt<Logger>();
  logger.d("📥 [FavPage] 正在拉取收藏歌单详情...");

  // 监听 ID 变化，实现列表实时刷新 (可选)
  // ref.watch(favoriteIdsProvider);

  try {
    final repository = getIt<FavoritesRepository>();
    final songs = await repository.getMyFavorites();
    logger.i("✅ [FavPage] 歌单加载成功，共 ${songs.length} 首");
    return songs;
  } catch (e, stack) {
    logger.e("❌ [FavPage] 歌单加载失败", error: e, stackTrace: stack);
    rethrow;
  }
});
