import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/library/domain/entities/playlist.dart';
import 'package:music_app/features/library/presentation/providers/library_providers.dart';

// 【临时 Provider】用于让 UI 跑通，后续你会替换为真正的 API 调用
final myPlaylistsProvider =
    FutureProvider.autoDispose<List<Playlist>>((ref) async {
  // 模拟网络延迟
  await Future.delayed(const Duration(seconds: 1));
  // 返回假数据
  return [
    const Playlist(id: '1', name: 'My Favorites', songCount: 12),
    const Playlist(id: '2', name: 'Coding Music', songCount: 45),
    const Playlist(id: '3', name: 'Workout', songCount: 8),
  ];
});

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(myPlaylistsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Library"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: Color(0xFFFACD66)), // 金色
            onPressed: () => _showCreateDialog(context, ref),
            tooltip: "Create Playlist",
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: playlistsAsync.when(
        data: (playlists) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.white.withValues(alpha: 0.6),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.album, color: Colors.white54),
                ),
                title: Text(
                  playlist.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${playlist.songCount} songs",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
                trailing:
                    const Icon(Icons.chevron_right, color: Colors.white24),
                onTap: () {
                  // TODO: 跳转详情页
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Opened playlist: ${playlist.name}")),
                  );
                },
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title:
            const Text("New Playlist", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter playlist name",
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.3))),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFACD66))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFACD66)),
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              // 1. 关闭弹窗 (先关再请求，体验更好，或者加 loading)
              Navigator.pop(context);

              // 2. 调用 Controller
              final success = await ref
                  .read(libraryControllerProvider)
                  .createPlaylist(nameController.text);

              // 3. 提示结果
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? "Playlist created!"
                        : "Failed to create playlist"),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text("Create",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
