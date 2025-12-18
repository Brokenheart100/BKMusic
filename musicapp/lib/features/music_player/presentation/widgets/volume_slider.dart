import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';

class VolumeSlider extends ConsumerWidget {
  const VolumeSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 【核心修复】监听音量状态流
    final volumeAsync = ref.watch(volumeProvider);
    // 如果还没加载好，默认显示 1.0 (最大音量)
    final currentVolume = volumeAsync.value ?? 0.5;

    return Row(
      children: [
        const Icon(Icons.volume_down_rounded, size: 20, color: Colors.white54),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
            ),
            child: Slider(
              // 【核心修复】使用真实音量值
              value: currentVolume.clamp(0.0, 1.0),
              onChanged: (value) {
                ref.read(playerControllerProvider).setVolume(value);
              },
            ),
          ),
        ),
        const Icon(Icons.volume_up_rounded, size: 20, color: Colors.white54),
      ],
    );
  }
}
