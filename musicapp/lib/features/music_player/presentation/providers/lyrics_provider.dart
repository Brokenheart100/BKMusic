import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart'; // 引入 MediaItem
import 'package:flutter_riverpod/legacy.dart';
import 'package:music_app/core/di/riverpod_bridge.dart';
import 'package:music_app/core/utils/lyric_parser.dart';
import 'package:music_app/features/music_player/domain/entities/lyric.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';

// 1. 歌词状态管理器
class LyricsNotifier extends StateNotifier<AsyncValue<Lyric>> {
  final Ref _ref;

  // 初始状态设为 Loading
  LyricsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // 【核心修复 1】初始化时，先主动读取一次当前歌曲
    final currentSongAsync = _ref.read(currentSongProvider);
    _handleSongChange(currentSongAsync.value);

    // 【核心修复 2】监听后续变化
    _ref.listen<AsyncValue<MediaItem?>>(currentSongProvider, (prev, next) {
      _handleSongChange(next.value);
    });
  }

  // 统一处理歌曲变化逻辑
  void _handleSongChange(MediaItem? song) {
    if (song == null) {
      state = const AsyncValue.data(Lyric.empty);
      return;
    }

    // 打印日志方便调试
    // print("LyricsNotifier: 切换歌曲 -> ${song.title}, ID: ${song.id}");

    // 判断是网络歌曲还是本地歌曲
    final lyricUrl = song.extras?['lyricUrl'] as String?;

    if (lyricUrl != null && lyricUrl.isNotEmpty) {
      _fetchRemoteLyrics(lyricUrl);
    } else {
      // 没有 URL，置空
      state = const AsyncValue.data(Lyric.empty);
    }
  }

  Future<void> _fetchRemoteLyrics(String url) async {
    state = const AsyncValue.loading();
    try {
      // 使用 Dio 下载歌词文本
      // 注意：这里新建 Dio 或者用 GetIt 里的都行，但要确保 ResponseType 是 plain
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(responseType: ResponseType.plain), // 强制作为文本读取
      );

      final lrcContent = response.data.toString();
      final lyric = LyricParser.parse(lrcContent);

      state = AsyncValue.data(lyric);
    } catch (e) {
      // 下载失败（比如 404），显示空状态或错误
      // state = AsyncValue.error(e, st);
      // 建议：如果下载失败，静默失败显示无歌词即可，不要红屏报错
      state = const AsyncValue.data(Lyric.empty);
    }
  }

  // 手动加载本地歌词
  void setLyrics(String lrcContent) {
    try {
      final lyric = LyricParser.parse(lrcContent);
      state = AsyncValue.data(lyric);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// 2. 注册 Provider
final lyricsProvider =
    StateNotifierProvider<LyricsNotifier, AsyncValue<Lyric>>((ref) {
  return LyricsNotifier(ref);
});

// 3. 当前歌词行索引 Provider
final currentLyricIndexProvider = StreamProvider.autoDispose<int>((ref) {
  final lyricAsync = ref.watch(lyricsProvider);
  final positionStream = ref.watch(audioManagerProvider).positionDataStream;

  return lyricAsync.when(
    data: (lyric) {
      if (lyric.lines.isEmpty) return Stream.value(0);
      return positionStream
          .map((pos) => lyric.getLineIndexByTime(pos.position))
          .distinct();
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});
