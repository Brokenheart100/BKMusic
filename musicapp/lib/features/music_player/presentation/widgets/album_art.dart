import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AlbumArt extends StatelessWidget {
  final String? url;
  final double size;
  final double borderRadius;
  final bool withShadow;

  const AlbumArt({
    super.key,
    required this.url,
    this.size = 50,
    this.borderRadius = 8,
    this.withShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    // 【核心修复】删除了这里的 Hero 组件，只返回 Container
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.grey[900],
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[850]),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.music_note, color: Colors.white24),
              )
            : const Icon(Icons.music_note, color: Colors.white24),
      ),
    );
  }
}
