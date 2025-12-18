import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';
import 'package:music_app/features/music_player/presentation/widgets/play_pause_button.dart';

class PlayerControls extends ConsumerWidget {
  final double iconSize;
  final double playButtonSize;

  const PlayerControls({
    super.key,
    this.iconSize = 28,
    this.playButtonSize = 64,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(playerControllerProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.shuffle, size: iconSize * 0.8),
          color: Colors.white38, // 暂时置灰，后续接通 Shuffle 状态
          onPressed: () {},
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(Icons.skip_previous_rounded, size: iconSize),
          color: Colors.white,
          onPressed: controller.skipToPrevious,
        ),
        const SizedBox(width: 16),
        PlayPauseButton(size: playButtonSize), // 复用之前的原子组件
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(Icons.skip_next_rounded, size: iconSize),
          color: Colors.white,
          onPressed: controller.skipToNext,
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(Icons.repeat, size: iconSize * 0.8),
          color: Colors.white38, // 暂时置灰
          onPressed: () {},
        ),
      ],
    );
  }
}
