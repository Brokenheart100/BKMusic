import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:music_app/core/ui/animate_list_tile.dart';
import 'package:music_app/features/home/domain/entities/song.dart';
import 'package:music_app/features/home/presentation/widgets/song_row_card.dart';

/// 通用的音乐集合展示视图
/// 用于：歌单详情页、我喜欢的音乐页、专辑详情页
class MusicCollectionView extends StatelessWidget {
  final String title;
  final String? description;
  final String? creatorName; // 创建者 (例如用户昵称或歌手名)
  final String? coverUrl; // 封面图 (网络)
  final Widget? coverPlaceholder; // 封面占位符 (本地图标，用于 Favorites)
  final List<Song> songs;
  final String? currentSongId; // 当前播放的歌曲ID，用于高亮
  final VoidCallback onPlayAll;
  final VoidCallback onBack;

  const MusicCollectionView({
    super.key,
    required this.title,
    this.description,
    this.creatorName,
    this.coverUrl,
    this.coverPlaceholder,
    required this.songs,
    this.currentSongId,
    required this.onPlayAll,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: onBack,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // 1. 背景层：高斯模糊
          if (coverUrl != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: CachedNetworkImage(
                  imageUrl: coverUrl!,
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 0.6),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            )
          else
            // 默认背景：深色渐变
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4A148C),
                    Color(0xFF091227)
                  ], // 紫色调适合 Favorites
                ),
              ),
            ),

          // 2. 渐变遮罩
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
          ),

          // 3. 滚动内容
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _CollectionHeader(
                  title: title,
                  description: description,
                  creatorName: creatorName,
                  coverUrl: coverUrl,
                  coverPlaceholder: coverPlaceholder,
                  songCount: songs.length,
                  onPlayAll: onPlayAll,
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.1, end: 0, curve: Curves.easeOut),
              ),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = songs[index];
                      // return SongRowCard(
                      //   song: song,
                      //   isPlaying: currentSongId == song.url,
                      // );
                      return AnimateListTile(
                        index: index,
                        child: SongRowCard(
                          song: song,
                          isPlaying: currentSongId == song.url,
                        ),
                      );
                    },
                    childCount: songs.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  final String title;
  final String? description;
  final String? creatorName;
  final String? coverUrl;
  final Widget? coverPlaceholder;
  final int songCount;
  final VoidCallback onPlayAll;

  const _CollectionHeader({
    required this.title,
    this.description,
    this.creatorName,
    this.coverUrl,
    this.coverPlaceholder,
    required this.songCount,
    required this.onPlayAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 100, 40, 40),
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment:
            isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.center,
        children: [
          // 封面
          Hero(
            tag: 'collection_cover_$title',
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  )
                ],
                image: coverUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(coverUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                // 如果没有 URL，显示背景色
                color: coverUrl == null ? Colors.deepPurple.shade800 : null,
              ),
              // 如果没有 URL，显示占位符（比如爱心图标）
              child: coverUrl == null
                  ? Center(
                      child: coverPlaceholder ??
                          const Icon(Icons.music_note,
                              size: 80, color: Colors.white24))
                  : null,
            ),
          ),

          SizedBox(width: isDesktop ? 32 : 0, height: isDesktop ? 0 : 32),

          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: isDesktop
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "PLAYLIST",
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (description != null)
                  Text(
                    description!,
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: isDesktop
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    // 创建者头像（可选，这里简化为文字）
                    Text(
                      creatorName ?? "Unknown User",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Text("•", style: TextStyle(color: Colors.white54)),
                    const SizedBox(width: 8),
                    Text(
                      "$songCount songs",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 播放按钮
                FilledButton.icon(
                  onPressed: onPlayAll,
                  icon: const Icon(Icons.play_arrow, color: Colors.black),
                  label: const Text("Play",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
