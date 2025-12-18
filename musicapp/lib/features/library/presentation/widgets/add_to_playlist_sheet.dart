import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 【核心修复】引入刚才创建的 providers 文件
import 'package:music_app/features/library/presentation/providers/library_providers.dart';

class AddToPlaylistSheet extends ConsumerWidget {
  final String songId;

  const AddToPlaylistSheet({super.key, required this.songId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用引入的 provider
    final playlistsAsync = ref.watch(myPlaylistsProvider);

    return Container(
      height: 400,
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Add to Playlist",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: playlistsAsync.when(
              data: (playlists) => ListView.builder(
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child:
                          const Icon(Icons.queue_music, color: Colors.white70),
                    ),
                    title: Text(playlist.name,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text("${playlist.songCount} songs",
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5))),
                    onTap: () {
                      // 【核心修复】现在 libraryControllerProvider 已经定义了，可以调用了
                      ref
                          .read(libraryControllerProvider)
                          .addSongToPlaylist(playlist.id, songId);

                      Navigator.pop(context); // 关闭弹窗

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Added to playlist!"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, __) => Center(
                  child: Text("Error: $err",
                      style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }
}
