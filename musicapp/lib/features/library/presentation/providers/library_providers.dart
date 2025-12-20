import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/features/library/data/datasources/playlist_api.dart';
import 'package:music_app/features/library/domain/entities/playlist.dart';
import 'package:music_app/features/library/domain/entities/playlist_detail.dart';

// 1. 歌单列表数据源
final myPlaylistsProvider =
    FutureProvider.autoDispose<List<Playlist>>((ref) async {
  final logger = getIt<Logger>();
  final api = ref.watch(playlistApiProvider);

  logger.d("📥 [Library] 正在加载用户歌单列表...");

  try {
    final response = await api.getMyPlaylists();

    if (response.isSuccess && response.value != null) {
      final playlists = response.value!
          .map((dto) => Playlist(
                id: dto.id,
                name: dto.name,
                songCount: dto.songCount,
                coverUrl: dto.coverUrl,
              ))
          .toList();
      return playlists;
    } else {
      return [];
    }
  } catch (e, stack) {
    logger.e("❌ [Library] 获取歌单发生异常", error: e, stackTrace: stack);
    rethrow;
  }
});

final playlistApiProvider = Provider<PlaylistApi>((ref) {
  return getIt<PlaylistApi>();
});

// 2. Library 控制器 Provider
final libraryControllerProvider = Provider<LibraryController>((ref) {
  return LibraryController(ref);
});

final libraryRepositoryProvider = Provider<PlaylistApi>((ref) {
  return getIt<PlaylistApi>();
});

final playlistDetailProvider =
    FutureProvider.family.autoDispose<PlaylistDetail, String>((ref, id) async {
  final api = ref.watch(playlistApiProvider); // 直接用 API 或 Repository 都可以
  final response = await api.getPlaylistDetail(id);

  if (response.isSuccess && response.value != null) {
    final dto = response.value!;
    return PlaylistDetail(
      id: dto.id,
      name: dto.name,
      // 假设后端 DTO 有 description 和 coverUrl (如果没有，用第一首歌封面做封面)
      coverUrl: dto.songs.isNotEmpty ? dto.songs.first.coverUrl : null,
      songs: dto.songs.map((s) => s.toEntity()).toList(),
    );
  }
  throw Exception("Playlist not found");
});

// 3. 控制器逻辑
class LibraryController {
  final Ref _ref;
  final Logger _logger = getIt<Logger>();

  LibraryController(this._ref);

  Future<bool> createPlaylist(String name, {String? description}) async {
    try {
      final api = _ref.read(libraryRepositoryProvider);
      final response =
          await api.createPlaylist({"name": name, "description": description});

      if (response.isSuccess) {
        _ref.invalidate(myPlaylistsProvider);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _logger.e("Create playlist error", error: e);
      return false;
    }
  }

  // 【核心修复】将返回类型从 Future<void> 改为 Future<bool>
  Future<bool> addSongToPlaylist(String playlistId, String songId) async {
    _logger.i("➕ [Library] 正在添加歌曲 ($songId) 到歌单 ($playlistId)...");

    try {
      final api = _ref.read(libraryRepositoryProvider);

      // 调用 API
      final response =
          await api.addSongToPlaylist(playlistId, {"songId": songId});

      if (response.isSuccess) {
        _logger.i("✅ [Library] 添加成功!");
        // 刷新列表以更新计数
        _ref.invalidate(myPlaylistsProvider);

        // 【核心修复】返回 true
        return true;
      } else {
        _logger.w("⚠️ [Library] 添加失败: ${response.error}");
        // 【核心修复】返回 false
        return false;
      }
    } catch (e, stack) {
      _logger.e("❌ [Library] 添加歌曲异常", error: e, stackTrace: stack);
      // 【核心修复】返回 false
      return false;
    }
  }
}
