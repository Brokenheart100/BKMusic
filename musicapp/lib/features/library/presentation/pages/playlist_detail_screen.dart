import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/core/router/app_router.dart';
import 'package:music_app/features/home/domain/entities/song.dart';
import 'package:music_app/features/home/presentation/widgets/song_row_card.dart'; // 复用之前的卡片
import 'package:music_app/features/library/domain/entities/playlist_detail.dart';
import 'package:music_app/features/library/presentation/providers/library_providers.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(playlistDetailProvider(playlistId));
    final controller = ref.read(playerControllerProvider);
    final currentSong = ref.watch(currentSongProvider).value;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          const SizedBox(width: 16),
        ],
      ),
      body: playlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (playlist) {
          return Stack(
            children: [
              // 1. 背景层：高斯模糊大图
              if (playlist.coverUrl != null)
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                    child: CachedNetworkImage(
                      imageUrl: playlist.coverUrl!,
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.6), // 压暗
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2E3852), Color(0xFF091227)],
                    ),
                  ),
                ),

              // 2. 渐变遮罩 (让底部变黑，衔接列表)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. 滚动内容
              CustomScrollView(
                slivers: [
                  // 头部：封面 + 信息 + 按钮
                  SliverToBoxAdapter(
                    child: _PlaylistHeader(
                      playlist: playlist,
                      onPlayAll: () {
                        // TODO: 实现播放整个列表逻辑
                        // controller.playPlaylist(playlist.songs);
                      },
                    ),
                  ),

                  // 列表：歌曲
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = playlist.songs[index];
                          return SongRowCard(
                            song: song,
                            isPlaying: currentSong?.id == song.url,
                          );
                        },
                        childCount: playlist.songs.length,
                      ),
                    ),
                  ),

                  // 底部留白
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlaylistHeader extends StatelessWidget {
  final PlaylistDetail playlist;
  final VoidCallback onPlayAll;

  const _PlaylistHeader({required this.playlist, required this.onPlayAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 100, 40, 40),
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment:
            isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.center,
        children: [
          // 封面
          Hero(
            tag: 'playlist_${playlist.id}',
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  )
                ],
                image: playlist.coverUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(playlist.coverUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: Colors.grey[800],
              ),
              child: playlist.coverUrl == null
                  ? const Icon(Icons.music_note,
                      size: 80, color: Colors.white24)
                  : null,
            ),
          ),

          SizedBox(width: isDesktop ? 32 : 0, height: isDesktop ? 0 : 32),

          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: isDesktop
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  playlist.name,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  playlist.description ?? "No description provided.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  playlist.stats,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 24),

                // 操作按钮栏
                Row(
                  mainAxisAlignment: isDesktop
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    // Play All (金色)
                    FilledButton.icon(
                      onPressed: onPlayAll,
                      icon: const Icon(Icons.play_circle_fill,
                          color: Colors.black),
                      label: const Text("Play all",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary, // #FACD66
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 18),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Add to Collection (半透明)
                    FilledButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.library_add_check,
                          color: theme.colorScheme.primary),
                      label: const Text("Added"),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 18),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Like (圆形)
                    IconButton.filled(
                      onPressed: () {},
                      icon: const Icon(Icons.favorite, color: Colors.redAccent),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
