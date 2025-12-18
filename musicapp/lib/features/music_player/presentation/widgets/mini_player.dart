import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/core/router/app_router.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';
import 'package:music_app/features/music_player/presentation/widgets/album_art.dart';
import 'package:music_app/features/music_player/presentation/widgets/play_pause_button.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songAsync = ref.watch(currentSongProvider);
    final theme = Theme.of(context);

    return songAsync.when(
      data: (song) {
        final hasSong = song != null;
        final title = hasSong ? song.title : "Enterprise Music";
        final artist = hasSong ? (song.artist ?? "Unknown") : "Ready to Play";
        final artUrl = hasSong ? song.artUri?.toString() : null;
        final heroTag = artUrl ?? 'default_art_tag';

        return GestureDetector(
          onTap: hasSong ? () => context.push(Routes.player) : null,
          behavior: HitTestBehavior.translucent,
          child: Container(
            height: 80,
            // 【修改】稍微加大左右内边距，适应全宽布局
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: const BoxDecoration(
              // 背景透明，由父级处理
              color: Colors.transparent,
            ),
            child: Row(
              children: [
                Hero(
                  tag: heroTag,
                  child: AlbumArt(
                    url: artUrl,
                    size: 56,
                    borderRadius: 8, // 稍微方一点更像桌面端
                    withShadow: hasSong,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          // 【修改】API 更新
                          color: hasSong
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          // 【修改】API 更新
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Opacity(
                  opacity: hasSong ? 1.0 : 0.3,
                  child: IgnorePointer(
                    ignoring: !hasSong,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded),
                          color: Colors.white,
                          onPressed:
                              ref.read(playerControllerProvider).skipToPrevious,
                        ),
                        const SizedBox(width: 16),
                        const PlayPauseButton(size: 48),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded),
                          color: Colors.white,
                          onPressed:
                              ref.read(playerControllerProvider).skipToNext,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => _buildPlaceholder(),
      error: (_, __) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 80,
      color: Colors.transparent,
      child: const Center(child: Text("Loading...")),
    );
  }
}
