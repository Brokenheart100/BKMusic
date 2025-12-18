import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/home/domain/entities/song.dart';
import 'package:music_app/features/library/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';
import 'package:music_app/features/music_player/presentation/widgets/album_art.dart';

class SongListTile extends ConsumerWidget {
  final Song song;

  const SongListTile({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(playerControllerProvider);
    final currentSong = ref.watch(currentSongProvider).value;

    // 判断当前是否正在播放这首歌，如果是，高亮显示
    // 注意：这里简单通过 URL 判断，实际项目中最好用 ID
    final isPlaying = currentSong?.id == song.url;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      // 1. 封面图 (复用之前的 AlbumArt 组件)
      leading: AlbumArt(
        url: song.coverUrl,
        size: 50,
        borderRadius: 6,
      ),

      // 2. 歌名
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color:
              isPlaying ? Theme.of(context).colorScheme.primary : Colors.white,
        ),
      ),

      // 3. 歌手 - 专辑
      subtitle: Text(
        "${song.artist} • ${song.album}",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.6), // 使用新 API
        ),
      ),

      // 4. 更多操作按钮
      trailing: IconButton(
        icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.5)),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (_) => AddToPlaylistSheet(songId: song.id),
          );
        },
      ),

      // 5. 点击播放
      onTap: () {
        // 转换 Domain Entity -> MediaItem
        final mediaItem = MediaItem(
          id: song.url,
          title: song.title,
          artist: song.artist,
          album: song.album,
          artUri: song.coverUrl != null ? Uri.parse(song.coverUrl!) : null,
        );
        controller.playMediaItem(mediaItem);
      },
    );
  }
}
