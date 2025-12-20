import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/library/presentation/providers/library_providers.dart';

class AddToPlaylistSheet extends ConsumerWidget {
  final String songId;

  const AddToPlaylistSheet({super.key, required this.songId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(myPlaylistsProvider);
    final theme = Theme.of(context);

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border:
            Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          // 1. 标题栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.playlist_add, color: Colors.white),
                const SizedBox(width: 12),
                const Text(
                  "Add to Playlist",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const Spacer(),
                // 快速新建按钮
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("New"),
                  style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary),
                  onPressed: () {
                    // TODO: 在这里直接弹出新建对话框，建完自动添加
                    // 简单起见，提示用户去 Library 页创建
                    Navigator.pop(context);
                    // 可以跳转：context.go(Routes.library);
                  },
                )
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),

          // 2. 歌单列表
          Expanded(
            child: playlistsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, __) => Center(
                  child: Text("Error: $err",
                      style: const TextStyle(color: Colors.red))),
              data: (playlists) {
                if (playlists.isEmpty) {
                  return Center(
                    child: Text("No playlists found",
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5))),
                  );
                }

                return ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(6),
                          image: playlist.coverUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(playlist.coverUrl!),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: playlist.coverUrl == null
                            ? const Icon(Icons.music_note,
                                color: Colors.white24)
                            : null,
                      ),
                      title: Text(playlist.name,
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text("${playlist.songCount} songs",
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5))),
                      trailing: const Icon(Icons.add_circle_outline,
                          color: Colors.white24),

                      // 【核心交互】点击添加到此歌单
                      onTap: () async {
                        // 1. 关闭弹窗 (提升响应速度感)
                        Navigator.pop(context);

                        // 2. 调用 Controller
                        final success = await ref
                            .read(libraryControllerProvider)
                            .addSongToPlaylist(playlist.id, songId);

                        // 3. 显示结果 SnackBar
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? "Added to ${playlist.name}"
                                  : "Failed to add song"),
                              backgroundColor:
                                  success ? Colors.green : Colors.red,
                              behavior: SnackBarBehavior.floating,
                              width: 300,
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
