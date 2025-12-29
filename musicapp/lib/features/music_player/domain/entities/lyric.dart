class LyricLine {
  final Duration startTime;
  final String content;

  const LyricLine({required this.startTime, required this.content});
}

class Lyric {
  final List<LyricLine> lines;

  const Lyric({required this.lines});

  /// 根据当前播放时间查找对应的歌词行索引
  int getLineIndexByTime(Duration position) {
    if (lines.isEmpty) return 0;

    // 倒序查找，找到第一个 startTime <= position 的行
    for (int i = lines.length - 1; i >= 0; i--) {
      if (lines[i].startTime <= position) {
        return i;
      }
    }
    return 0;
  }

  // 空歌词
  static const empty = Lyric(lines: []);
}
