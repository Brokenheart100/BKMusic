import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/features/home/domain/entities/song.dart';

class HeroBanner extends StatelessWidget {
  final Song song;
  final VoidCallback onPlay;

  const HeroBanner({super.key, required this.song, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Container(
      // 只有移动端需要 padding，桌面端靠父级布局
      padding: isDesktop ? EdgeInsets.zero : const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 左侧大封面
          Hero(
            tag: 'banner_art',
            child: Container(
              width: isDesktop ? 300 : 160,
              height: isDesktop ? 260 : 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                image: DecorationImage(
                  image: CachedNetworkImageProvider(song.coverUrl ?? ""),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),

          // 2. 右侧信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Text(
                  "Tomorrow's tunes",
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Lorem ipsum dolor sit amet, consectetur adipiscing elit ut aliquam, purus sit amet luctus venenatis",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Text(
                  "64 songs ~ 16 hrs+",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // 按钮组
                Row(
                  children: [
                    // Play All Button (金色背景)
                    ElevatedButton.icon(
                      onPressed: onPlay,
                      icon: const Icon(Icons.play_circle_fill,
                          color: Colors.black),
                      label: const Text("Play all",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Add to Collection (半透明背景)
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.library_music,
                          color: theme.colorScheme.primary),
                      label: const Text("Add to collection"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Like Button
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.redAccent),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
