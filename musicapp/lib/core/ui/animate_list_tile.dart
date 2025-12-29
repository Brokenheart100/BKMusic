import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimateListTile extends StatelessWidget {
  final int index;
  final Widget child;
  final double delayFactor; // 延迟系数，控制错峰感强弱

  const AnimateListTile({
    super.key,
    required this.index,
    required this.child,
    this.delayFactor = 0.05, // 默认每个 item 间隔 50ms
  });

  @override
  Widget build(BuildContext context) {
    // 动画逻辑：
    // 1. 初始透明度 0 -> 1 (Fade)
    // 2. 初始位置向下偏移 20px -> 0 (Slide)
    // 3. 错峰延迟：index * factor
    return child
        .animate()
        .fadeIn(
          duration: 600.ms,
          delay: (index * delayFactor).seconds,
          curve: Curves.easeOutQuad,
        )
        .slideY(
          begin: 0.1, // 从下方 10% 的位置浮上来
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutQuart,
        )
        // 可选：加一点微弱的 Shimmer 扫光效果，增加高级感
        .shimmer(
          duration: 1200.ms,
          color: Colors.white.withValues(alpha: 0.5),
          angle: 0.8,
        );
  }
}
