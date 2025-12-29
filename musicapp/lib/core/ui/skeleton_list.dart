import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 8, // 假装有8个
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // 封面占位
              Container(
                  width: 48,
                  height: 48,
                  color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(width: 24),
              // 文字占位
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 120,
                        height: 14,
                        color: Colors.white.withValues(alpha: 0.1)),
                    const SizedBox(height: 8),
                    Container(
                        width: 80,
                        height: 12,
                        color: Colors.white.withValues(alpha: 0.05)),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate(onPlay: (controller) => controller.repeat()) // 循环播放
            .shimmer(
                duration: 1200.ms,
                color: Colors.white.withValues(alpha: 0.1)) // 扫光效果
            .animate() // 再次链式调用，做入场
            .fadeIn(duration: 600.ms, delay: (index * 0.05).seconds); // 错峰入场
      },
    );
  }
}
