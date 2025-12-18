import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';

class PlayPauseButton extends ConsumerWidget {
  final double size;

  const PlayPauseButton({super.key, this.size = 64});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlayingAsync = ref.watch(playerStateProvider);
    final controller = ref.read(playerControllerProvider);
    final theme = Theme.of(context);

    return isPlayingAsync.when(
      data: (isPlaying) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            // 霓虹发光效果
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: IconButton(
          iconSize: size,
          // 纯色背景填充的按钮更符合 Figma 设计
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
          ),
          color: theme.colorScheme.primary, // 玫红色
          padding: EdgeInsets.zero,
          onPressed: controller.togglePlay,
        ),
      ),
      loading: () => SizedBox(
        width: size,
        height: size,
        child: const Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const Icon(Icons.error),
    );
  }
}
