import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// 【核心修改】引入正式的 Provider 定义
import 'package:music_app/features/library/presentation/providers/library_providers.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 这里的 ref.watch 会自动找到 library_providers.dart 中定义的 myPlaylistsProvider
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
        data: (playlists) {
          if (playlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_music,
                      size: 64, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  const Text("No playlists yet",
                      style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => _showCreateDialog(context, ref),
                    child: const Text("Create One"),
                  )
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.white.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                      image: playlist.coverUrl != null
                          ? DecorationImage(
                              image: NetworkImage(playlist.coverUrl!),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: playlist.coverUrl == null
                        ? const Icon(Icons.music_note, color: Colors.white24)
                        : null,
                  ),
                  title: Text(playlist.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${playlist.songCount} songs",
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5))),
                  trailing:
                      const Icon(Icons.chevron_right, color: Colors.white24),
                  onTap: () {
                    if (playlist.id.isNotEmpty) {
                      // 使用 push 可以保留返回按钮逻辑
                      context.push('/playlists/${playlist.id}');
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            onPressed: () => Navigator.pop(dialogContext),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFACD66),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              Navigator.pop(dialogContext);

              // 调用 Controller
              final success = await ref
                  .read(libraryControllerProvider)
                  .createPlaylist(nameController.text);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? "Playlist created!" : "Failed to create"),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text("Create",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
