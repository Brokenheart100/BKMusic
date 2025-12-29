import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/core/router/app_router.dart';
import 'package:music_app/features/favorites/presentation/widgets/like_button.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';
import 'package:music_app/features/music_player/presentation/widgets/album_art.dart';
import 'package:music_app/features/music_player/presentation/widgets/play_pause_button.dart';

// 【修改 1】改为 Stateful 以支持 Hover 状态
class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  // 用于记录鼠标是否悬停在进度条上
  bool _isHoveringBar = false;

  @override
  Widget build(BuildContext context) {
    final songAsync = ref.watch(currentSongProvider);
    final theme = Theme.of(context);
    final progressAsync = ref.watch(progressProvider);

    return songAsync.when(
      data: (song) {
        final hasSong = song != null;
        final title = hasSong ? song.title : "Enterprise Music";
        final artist = hasSong ? (song.artist ?? "Unknown") : "Ready to Play";
        final artUrl = hasSong ? song.artUri?.toString() : null;
        final heroTag = artUrl ?? 'default_art_tag';
        final songId = song?.extras?['songId'] as String?;

        return Stack(
          // 允许超出 Stack 边界显示（为了让进度条圆点不被截断）
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // 1. 原有内容 (背景 + Row)
            GestureDetector(
              onTap: hasSong ? () => context.push(Routes.player) : null,
              behavior: HitTestBehavior.translucent,
              child: Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Row(
                  children: [
                    Hero(
                      tag: heroTag,
                      child: AlbumArt(
                          url: artUrl,
                          size: 56,
                          borderRadius: 8,
                          withShadow: hasSong),
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
                            if (hasSong && songId != null) ...[
                              LikeButton(songId: songId, size: 24),
                              const SizedBox(width: 16),
                            ],
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded),
                              color: Colors.white,
                              onPressed: ref
                                  .read(playerControllerProvider)
                                  .skipToPrevious,
                            ),
                            const SizedBox(width: 12),
                            const PlayPauseButton(size: 48),
                            const SizedBox(width: 12),
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
            ),

            // 2. 顶部进度条 (增强交互版)
            if (hasSong)
              Positioned(
                // 让进度条容器的中心线对齐 MiniPlayer 的上边缘
                // 容器高 10，向上偏移 5，正好居中
                top: -5,
                left: 0,
                right: 0,
                height: 10,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _isHoveringBar = true),
                  onExit: (_) => setState(() => _isHoveringBar = false),
                  // 使用 OverflowBox 允许进度条圆点超出容器高度
                  child: OverflowBox(
                    maxHeight: 20, // 给足够的高度画圆点
                    minHeight: 10,
                    child: progressAsync.when(
                      data: (data) => ProgressBar(
                        progress: data.position,
                        buffered: data.bufferedPosition,
                        total: data.duration,
                        onSeek: (duration) =>
                            ref.read(playerControllerProvider).seek(duration),

                        // 样式配置
                        barHeight: _isHoveringBar ? 4 : 2,
                        baseBarColor: Colors.transparent, // 透明底
                        bufferedBarColor: Colors.white.withValues(alpha: 0.2),
                        progressBarColor: theme.colorScheme.primary,
                        thumbColor: theme.colorScheme.primary,

                        // 悬停时显示圆点
                        thumbRadius: _isHoveringBar ? 6 : 0,
                        thumbGlowRadius: 12,

                        timeLabelLocation: TimeLabelLocation.none,
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ),
                ),
              ),
          ],
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
