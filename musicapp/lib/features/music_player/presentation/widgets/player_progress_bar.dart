import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';

class PlayerProgressBar extends ConsumerWidget {
  const PlayerProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(progressProvider);
    final controller = ref.read(playerControllerProvider);
    final theme = Theme.of(context);

    return progressAsync.when(
      data: (data) => ProgressBar(
        progress: data.position,
        buffered: data.bufferedPosition,
        total: data.duration,
        onSeek: (duration) => controller.seek(duration),

        // 【关键修改】使用 Theme 颜色
        baseBarColor: Colors.white.withValues(alpha: 0.1), // 底色更淡
        bufferedBarColor: Colors.white.withValues(alpha: 0.3),
        progressBarColor: theme.colorScheme.primary, // 使用玫红色
        thumbColor: Colors.white,
        thumbRadius: 8,
        thumbGlowRadius: 20,

        // 字体样式
        timeLabelLocation: TimeLabelLocation.sides,
        timeLabelTextStyle: theme.textTheme.bodySmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.5),
          fontFeatures: [const FontFeature.tabularFigures()], // 等宽数字，防止跳动
        ),
      ),
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (_, s) => const SizedBox.shrink(),
    );
  }
}
