import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/features/library/data/datasources/playlist_api.dart';
import 'package:music_app/features/library/domain/entities/playlist.dart';

// 1. 歌单列表 Provider
// (这里暂时用假数据，后续对接 API 时替换为 Repository 调用)
final myPlaylistsProvider =
    FutureProvider.autoDispose<List<Playlist>>((ref) async {
  // 模拟网络请求
  await Future.delayed(const Duration(milliseconds: 500));

  return [
    const Playlist(id: '1', name: 'My Favorites', songCount: 12),
    const Playlist(id: '2', name: 'Coding Music', songCount: 45),
    const Playlist(id: '3', name: 'Workout', songCount: 8),
    const Playlist(id: '4', name: 'Sleep', songCount: 20),
  ];
});

// 2. Library 控制器 Provider
final libraryControllerProvider = Provider<LibraryController>((ref) {
  return LibraryController(ref);
});

final libraryRepositoryProvider = Provider<PlaylistApi>((ref) {
  return getIt<PlaylistApi>(); // 从 DI 容器获取 Retrofit 实例
});

// 3. 控制器逻辑
class LibraryController {
  final Ref _ref;

  LibraryController(this._ref);

  Future<bool> createPlaylist(String name, {String? description}) async {
    try {
      final api = _ref.read(libraryRepositoryProvider);

      // 调用后端
      final response =
          await api.createPlaylist({"name": name, "description": description});

      if (response.isSuccess) {
        // 【关键】创建成功后，强制刷新歌单列表，让 UI 自动更新
        _ref.invalidate(myPlaylistsProvider);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Create playlist error: $e");
      return false;
    }
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    // TODO: 调用 Repository.addSongToPlaylist(playlistId, songId)
    print("Adding song $songId to playlist $playlistId");

    // 模拟成功
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
