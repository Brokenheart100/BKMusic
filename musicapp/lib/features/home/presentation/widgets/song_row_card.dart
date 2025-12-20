import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/favorites/presentation/widgets/like_button.dart';
import 'package:music_app/features/home/domain/entities/song.dart';
import 'package:music_app/features/library/presentation/widgets/add_to_playlist_sheet.dart';
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

  // 触发播放逻辑
  void _play() {
    final controller = ref.read(playerControllerProvider);
    controller.playMediaItem(MediaItem(
      id: widget.song.url,
      title: widget.song.title,
      artist: widget.song.artist,
      album: widget.song.album,
      artUri: widget.song.coverUrl != null
          ? Uri.parse(widget.song.coverUrl!)
          : null,
      extras: {'songId': widget.song.id},
    ));
  }

  // 显示右键菜单
  void _showContextMenu(BuildContext context, Offset position) async {
    final theme = Theme.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    // 如果是点击按钮触发，位置计算不同，这里简化为通用处理
    final relativePosition = RelativeRect.fromRect(
      Rect.fromPoints(position, position),
      Offset.zero & overlay.size,
    );

    final result = await showMenu<String>(
      context: context,
      position: relativePosition,
      color: const Color(0xFF252529), // 截图中的深灰背景
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      items: [
        _buildMenuItem('play', Icons.play_arrow_rounded, '播放'),
        _buildMenuItem('play_next', Icons.playlist_play_rounded, '下一首播放'),
        const PopupMenuDivider(height: 1),
        _buildMenuItem(
            'comments', Icons.chat_bubble_outline_rounded, '查看评论 (99+)'),
        const PopupMenuDivider(height: 1),
        _buildMenuItem('add_to_playlist', Icons.add_box_rounded, '收藏到歌单'),
        _buildMenuItem('download', Icons.download_rounded, '下载'),
        _buildMenuItem('share', Icons.share_rounded, '分享'),
        _buildMenuItem('copy_link', Icons.content_copy_rounded, '复制链接'),
        const PopupMenuDivider(height: 1),
        _buildMenuItem('not_interested', Icons.block_rounded, '减少推荐'),
      ],
    );

    // 处理菜单点击
    if (result == 'play') {
      _play();
    } else if (result == 'add_to_playlist') {
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => AddToPlaylistSheet(songId: widget.song.id),
        );
      }
    } else if (result == 'play_next') {
      // TODO: 实现插入队列逻辑
    }
  }

  // 辅助构建菜单项
  PopupMenuItem<String> _buildMenuItem(
      String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white70),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor =
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final hoverColor =
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // behavior: HitTestBehavior.opaque,
        // 左键点击播放
        onTap: _play,
        // 【核心】右键点击弹出菜单
        onSecondaryTapDown: (details) {
          _showContextMenu(context, details.globalPosition);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovering ? hoverColor : cardColor,
            borderRadius: BorderRadius.circular(16),
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
                  errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.music_note)),
                ),
              ),
              const SizedBox(width: 24),

              // 2. 爱心 (复用 LikeButton)
              LikeButton(songId: widget.song.id, size: 22),
              const SizedBox(width: 24),

              // 3. 信息
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.song.title,
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
                    Text(
                      widget.song.artist,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

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

              Text("3:45",
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13)),
              const SizedBox(width: 16),

              // 6. 更多操作按钮 (点击同样弹出菜单)
              GestureDetector(
                onTapDown: (details) {
                  _showContextMenu(context, details.globalPosition);
                },
                child: Icon(Icons.more_vert, color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
