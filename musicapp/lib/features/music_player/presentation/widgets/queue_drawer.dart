import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';

class QueueDrawer extends ConsumerWidget {
  const QueueDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(queueProvider);
    final currentSongAsync = ref.watch(currentSongProvider);
    final controller = ref.read(playerControllerProvider);
    final theme = Theme.of(context);

    // 【关键修改】移除默认 Drawer，使用 Container + BackdropFilter
    return Container(
      width: 400,
      height: double.infinity,
      decoration: BoxDecoration(
        // 半透明背景，配合后面的 Blur
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
        border: Border(
            left: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              // 1. 标题栏
              Container(
                padding: const EdgeInsets.fromLTRB(24, 40, 16, 20),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05))),
                ),
                child: Row(
                  children: [
                    Text(
                      "Playing Queue",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    queueAsync.when(
                      data: (q) => Text(
                        "(${q.length})",
                        style: TextStyle(
                            color: theme.colorScheme.primary, fontSize: 18),
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // 2. 列表区域
              Expanded(
                child: queueAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text("Error: $err")),
                  data: (queue) {
                    if (queue.isEmpty) {
                      return Center(
                          child: Text("Queue is empty",
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3))));
                    }

                    final currentSong = currentSongAsync.value;

                    return ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: queue.length,
                      onReorder: controller.reorderQueue,
                      itemBuilder: (context, index) {
                        final item = queue[index];
                        final isPlaying = item.id == currentSong?.id;

                        return _QueueItem(
                          key: ValueKey(item.id),
                          index: index,
                          item: item,
                          isPlaying: isPlaying,
                          onTap: () => controller.skipToQueueItem(index),
                          onRemove: () => controller.removeFromQueue(index),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueItem extends StatelessWidget {
  final int index;
  final MediaItem item;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _QueueItem({
    required Key key,
    required this.index,
    required this.item,
    required this.isPlaying,
    required this.onTap,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error.withValues(alpha: 0.8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onRemove(),
      child: Material(
        // 为了点击水波纹
        color: isPlaying
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        child: ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          // 封面图
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              image: item.artUri != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(item.artUri.toString()),
                      fit: BoxFit.cover)
                  : null,
              color: Colors.grey[800],
            ),
            child: isPlaying
                ? Center(
                    child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.bar_chart_rounded,
                        size: 20, color: Colors.white),
                  ))
                : null,
          ),
          // 标题
          title: Text(
            item.title,
            style: TextStyle(
              color: isPlaying ? theme.colorScheme.primary : Colors.white,
              fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // 歌手
          subtitle: Text(
            item.artist ?? "Unknown",
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            maxLines: 1,
          ),
          // 拖拽手柄
          trailing: ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_indicator,
                color: Colors.white.withValues(alpha: 0.2)),
          ),
        ),
      ),
    );
  }
}
