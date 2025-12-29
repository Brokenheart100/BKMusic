import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/music_player/domain/entities/lyric.dart';
import 'package:music_app/features/music_player/presentation/providers/lyrics_provider.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class LyricsView extends ConsumerStatefulWidget {
  const LyricsView({super.key});

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  bool _isUserScrolling = false;

  @override
  Widget build(BuildContext context) {
    final lyricsAsync = ref.watch(lyricsProvider);
    final currentIndexAsync = ref.watch(currentLyricIndexProvider);
    final currentIndex = currentIndexAsync.value ?? 0;

    // 监听索引变化，自动滚动
    ref.listen(currentLyricIndexProvider, (prev, next) {
      if (next.value != null && !_isUserScrolling) {
        _scrollToIndex(next.value!);
      }
    });

    return lyricsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.white24)),
      // 【修复】传递 context 和 ref
      error: (_, __) => _buildNoLyricsState(context, ref),
      data: (lyric) {
        if (lyric.lines.isEmpty) {
          // 【修复】传递 context 和 ref
          return _buildNoLyricsState(context, ref);
        }

        return ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent
              ],
              stops: [0.0, 0.15, 0.85, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _isUserScrolling = true;
              } else if (notification is ScrollEndNotification) {
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) setState(() => _isUserScrolling = false);
                });
              }
              return false;
            },
            child: ScrollablePositionedList.builder(
              itemCount: lyric.lines.length,
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              padding: const EdgeInsets.symmetric(vertical: 200),
              itemBuilder: (context, index) {
                final line = lyric.lines[index];
                final isCurrent = index == currentIndex;

                return _LyricItem(
                  line: line,
                  isCurrent: isCurrent,
                  onTap: () {
                    ref.read(playerControllerProvider).seek(line.startTime);
                    setState(() => _isUserScrolling = false);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // 【修复】方法定义接收参数
  Widget _buildNoLyricsState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lyrics_outlined,
              size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            "No lyrics available",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.file_open, size: 18),
            label: const Text("Load Local .lrc"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              ref.read(playerControllerProvider).pickAndLoadLrc();
            },
          ),
        ],
      ),
    );
  }

  void _scrollToIndex(int index) {
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.5,
      );
    }
  }
}

class _LyricItem extends StatelessWidget {
  final LyricLine line;
  final bool isCurrent;
  final VoidCallback onTap;

  const _LyricItem({
    required this.line,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scale = isCurrent ? 1.0 : 0.9;
    final opacity = isCurrent ? 1.0 : 0.3;
    final fontWeight = isCurrent ? FontWeight.bold : FontWeight.normal;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: opacity,
            child: Text(
              line.content,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: fontWeight,
                height: 1.5,
                shadows: isCurrent
                    ? [
                        BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.6),
                            blurRadius: 20,
                            offset: const Offset(0, 0))
                      ]
                    : [],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
