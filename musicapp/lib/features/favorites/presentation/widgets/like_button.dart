import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/favorites/presentation/providers/favorites_provider.dart';

class LikeButton extends ConsumerWidget {
  final String songId;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const LikeButton({
    super.key,
    required this.songId,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听收藏 ID 集合
    final favoriteIds = ref.watch(favoriteIdsProvider);
    // 2. 判断当前歌曲是否在集合中 (O(1) 复杂度)
    final isLiked = favoriteIds.contains(songId);

    final theme = Theme.of(context);

    return IconButton(
      iconSize: size,
      icon: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        color: isLiked
            ? (activeColor ?? theme.colorScheme.primary) // 默认用主题色(黄色)
            : (inactiveColor ?? Colors.white24),
      ),
      tooltip: isLiked ? "Remove from Favorites" : "Add to Favorites",
      onPressed: () {
        // 3. 调用 Provider 进行乐观更新 + 网络请求
        ref.read(favoriteIdsProvider.notifier).toggle(songId);
      },
    );
  }
}
