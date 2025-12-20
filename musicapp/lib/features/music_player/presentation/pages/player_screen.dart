import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/favorites/presentation/widgets/like_button.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';
import 'package:music_app/features/music_player/presentation/widgets/album_art.dart';
import 'package:music_app/features/music_player/presentation/widgets/player_controls.dart';
import 'package:music_app/features/music_player/presentation/widgets/player_progress_bar.dart';
import 'package:music_app/features/music_player/presentation/widgets/queue_drawer.dart';
import 'package:music_app/features/music_player/presentation/widgets/volume_slider.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songAsync = ref.watch(currentSongProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      endDrawer: const QueueDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.queue_music_rounded, size: 28),
              tooltip: 'Playing Queue',
              onPressed: () {
                // 打开侧边抽屉
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: songAsync.when(
        data: (song) {
          if (song == null) return const Center(child: Text("No song playing"));
          final artUrl = song.artUri?.toString();
          final songId = song.extras?['songId'] as String?;

          return Stack(
            children: [
              // 1. 动态高斯模糊背景
              if (artUrl != null)
                Positioned.fill(
                  child:
                      CachedNetworkImage(imageUrl: artUrl, fit: BoxFit.cover),
                ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(color: Colors.black.withAlpha(77)),
                ),
              ),

              // 2. 内容层 (响应式)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 80 : 32, vertical: 40),
                    child: isDesktop
                        ? _DesktopLayout(
                            songId: songId,
                            songTitle: song.title,
                            artist: song.artist,
                            artUrl: artUrl)
                        : _MobileLayout(
                            songTitle: song.title,
                            artist: song.artist,
                            artUrl: artUrl),
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}

// --- 桌面端布局 (左右分栏) ---
class _DesktopLayout extends StatelessWidget {
  final String songTitle;
  final String? artist;
  final String? artUrl;
  final String? songId;

  const _DesktopLayout(
      {required this.songTitle, this.artist, this.artUrl, this.songId});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧：大封面
        Expanded(
          flex: 1,
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: AlbumArt(
                  url: artUrl, size: 400, borderRadius: 12, withShadow: true),
            ),
          ),
        ),
        const SizedBox(width: 80),
        // 右侧：控制区
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(songTitle,
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (songId != null) LikeButton(songId: songId!, size: 32),
                ],
              ),
              const SizedBox(height: 8),
              Text(artist ?? "",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white70)),
              const SizedBox(height: 48),
              const PlayerProgressBar(),
              const SizedBox(height: 24),
              const PlayerControls(playButtonSize: 80, iconSize: 32),
              const SizedBox(height: 48),
              // 音量控制 (仅桌面端显示)
              const SizedBox(width: 200, child: VolumeSlider()),
            ],
          ),
        ),
      ],
    );
  }
}

// --- 移动端布局 (垂直堆叠) ---
class _MobileLayout extends StatelessWidget {
  final String songTitle;
  final String? artist;
  final String? artUrl;

  const _MobileLayout({required this.songTitle, this.artist, this.artUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        AspectRatio(
          aspectRatio: 1,
          child: AlbumArt(
              url: artUrl, size: 300, borderRadius: 12, withShadow: true),
        ),
        const SizedBox(height: 48),
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(songTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(artist ?? "",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const PlayerProgressBar(),
        const SizedBox(height: 16),
        const PlayerControls(),
        const Spacer(),
      ],
    );
  }
}
