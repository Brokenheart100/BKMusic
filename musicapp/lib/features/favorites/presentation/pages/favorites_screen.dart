import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:music_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:music_app/features/library/presentation/widgets/music_collection_view.dart';
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
    // 刷新数据
    ref.read(favoriteIdsProvider.notifier).loadIds();
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(favoriteSongsProvider);
    final currentSong = ref.watch(currentSongProvider).value;
    final currentUser = ref.watch(currentUserProvider);

    return songsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text("Error: $err"))),
      data: (songs) {
        return MusicCollectionView(
          title: "Liked Songs",
          description: "Your personal collection of favorite tracks.",
          creatorName: currentUser?.nickname ?? "You",

          // 【核心】不传 coverUrl，传一个本地的爱心图标组件
          coverUrl: null,
          coverPlaceholder: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF450AF5), Color(0xFFC4EFDA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(Icons.favorite, size: 80, color: Colors.white),
            ),
          ),

          songs: songs,
          currentSongId: currentSong?.id,

          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // 如果没法退，去首页
              context.go('/');
            }
          },

          onPlayAll: () {
            if (songs.isEmpty) return;
            // 播放全部逻辑
            // 转换 Song -> MediaItem
            final items = songs
                .map((s) => MediaItem(
                    id: s.url,
                    title: s.title,
                    artist: s.artist,
                    album: s.album,
                    artUri: s.coverUrl != null ? Uri.parse(s.coverUrl!) : null,
                    extras: {'songId': s.id}))
                .toList();

            // 暂时只播第一首演示
            ref.read(playerControllerProvider).playMediaItem(items.first);
          },
        );
      },
    );
  }
}
