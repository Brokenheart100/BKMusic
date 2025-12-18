import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/home/domain/entities/song.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';

class SongRowCard extends ConsumerStatefulWidget {
  final Song song;
  final bool isPlaying;

  const SongRowCard({
    super.key,
    required this.song,
    this.isPlaying = false,
  });

  @override
  ConsumerState<SongRowCard> createState() => _SongRowCardState();
}

class _SongRowCardState extends ConsumerState<SongRowCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 截图中的深色卡片背景颜色
    final cardColor =
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final hoverColor =
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          final controller = ref.read(playerControllerProvider);
          controller.playMediaItem(MediaItem(
            id: widget.song.url,
            title: widget.song.title,
            artist: widget.song.artist,
            album: widget.song.album,
            artUri: widget.song.coverUrl != null
                ? Uri.parse(widget.song.coverUrl!)
                : null,
          ));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovering ? hoverColor : cardColor,
            borderRadius: BorderRadius.circular(16), // 较大的圆角
            border: _isHovering
                ? Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1)
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              // 1. 封面
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: widget.song.coverUrl ?? "",
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[800]),
                  errorWidget: (_, __, ___) => const Icon(Icons.music_note),
                ),
              ),
              const SizedBox(width: 24),

              // 2. 爱心图标
              Icon(
                widget.isPlaying ? Icons.favorite : Icons.favorite_border,
                color: widget.isPlaying
                    ? theme.colorScheme.primary
                    : Colors.white24,
                size: 20,
              ),
              const SizedBox(width: 24),

              // 3. 歌名 - 歌手
              Expanded(
                flex: 4,
                child: Text(
                  "${widget.song.title} - ${widget.song.artist}",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: widget.isPlaying
                        ? theme.colorScheme.primary
                        : Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 4. 专辑/类别 (响应式：窄屏隐藏)
              if (MediaQuery.of(context).size.width > 600)
                Expanded(
                  flex: 2,
                  child: Text(
                    widget.song.album,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // 5. 时长 (模拟)
              Text(
                "3:45", // 实际应从 Song 实体获取 Duration 并格式化
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
              const SizedBox(width: 24),

              // 6. 更多操作
              Icon(Icons.more_vert, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
