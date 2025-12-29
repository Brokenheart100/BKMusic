import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/features/library/presentation/providers/library_providers.dart';
import 'package:music_app/features/library/presentation/widgets/music_collection_view.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(playlistDetailProvider(playlistId));
    final currentSong = ref.watch(currentSongProvider).value;

    return playlistAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(child: Text("Error: $err")),
      ),
      data: (playlist) {
        return MusicCollectionView(
          title: playlist.name,
          description: playlist.description,
          creatorName: "Created by You", // 后续可从 API 获取创建者名
          coverUrl: playlist.coverUrl,
          songs: playlist.songs,
          currentSongId: currentSong?.id,

          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/library');
            }
          },

          onPlayAll: () {
            if (playlist.songs.isEmpty) return;
            final items = playlist.songs
                .map((s) => MediaItem(
                    id: s.url,
                    title: s.title,
                    artist: s.artist,
                    album: s.album,
                    artUri: s.coverUrl != null ? Uri.parse(s.coverUrl!) : null,
                    extras: {'songId': s.id}))
                .toList();

            // ref.read(playerControllerProvider).playList(items);
            ref.read(playerControllerProvider).playMediaItem(items.first);
          },
        );
      },
    );
  }
}
