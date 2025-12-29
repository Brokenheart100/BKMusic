import 'package:music_app/features/music_player/domain/entities/lyric.dart';

class LyricParser {
  static Lyric parse(String lrcContent) {
    final List<LyricLine> lines = [];
    final RegExp regex = RegExp(r"\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)");

    final rawLines = lrcContent.split('\n');

    for (var line in rawLines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisecondsStr = match.group(3)!;
        // 处理 2位或3位毫秒
        final milliseconds = millisecondsStr.length == 2
            ? int.parse(millisecondsStr) * 10
            : int.parse(millisecondsStr);

        final content = match.group(4)?.trim() ?? "";

        if (content.isNotEmpty) {
          lines.add(LyricLine(
            startTime: Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: milliseconds,
            ),
            content: content,
          ));
        }
      }
    }

    // 按时间排序，防止 LRC 文件顺序错乱
    lines.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Lyric(lines: lines);
  }
}
