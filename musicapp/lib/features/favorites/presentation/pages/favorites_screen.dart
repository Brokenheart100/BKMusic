import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:music_app/features/home/presentation/widgets/song_row_card.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // 进页面时刷新 ID 缓存
    ref.read(favoriteIdsProvider.notifier).loadIds();
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(favoriteSongsProvider);
    final currentSong = ref.watch(currentSongProvider).value;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Liked Songs"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.redAccent.withValues(alpha: 0.1), // 顶部微红
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: songsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text("Error: $err")),
          data: (songs) {
            if (songs.isEmpty) {
              return const Center(child: Text("No favorite songs yet"));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 100, 24, 100),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return SongRowCard(
                  song: song,
                  isPlaying: currentSong?.id == song.url,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
