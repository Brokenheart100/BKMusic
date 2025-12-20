import 'package:music_app/features/home/domain/entities/song.dart';

/// 收藏功能的抽象仓库接口
/// 位于 Domain 层，不依赖具体的数据实现细节 (如 Dio, Retrofit)
abstract class FavoritesRepository {
  /// 获取我收藏的所有歌曲列表（用于展示 "My Favorites" 页面）
  Future<List<Song>> getMyFavorites();

  /// 获取我收藏的所有歌曲 ID 集合
  /// 用于在首页/搜索页快速判断某首歌是否已收藏 (O(1) 查找效率)
  Future<Set<String>> getFavoriteIds();

  /// 切换收藏状态 (点赞/取消点赞)
  /// [songId] 歌曲ID
  /// 返回：最新的状态 (true=已收藏, false=未收藏)
  Future<bool> toggleFavorite(String songId);
}
