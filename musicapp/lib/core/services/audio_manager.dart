// 导入 audio_service 核心库
import 'package:audio_service/audio_service.dart';
// 导入 injectable 库
import 'package:injectable/injectable.dart';
// 导入自定义进度数据模型
import 'package:music_app/core/models/position_data.dart';
// 导入音频处理器
import 'package:music_app/core/services/audio_handler.dart';
// 导入 rxdart 库
import 'package:rxdart/rxdart.dart';

@singleton
class AudioManager {
  final MusicHandler _audioHandler;

  AudioManager(this._audioHandler);

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        // 1. 改用底层直连的 positionStream (不再用 AudioService.position)
        _audioHandler.positionStream,

        // 2. 缓冲进度依然从 playbackState 拿 (或者你也可以暴露 bufferedPositionStream)
        _audioHandler.playbackState.map((state) => state.bufferedPosition),

        // 3. 改用底层直连的 durationStream (不再等 MediaItem 更新)
        _audioHandler.durationStream,

        (position, buffered, duration) =>
            PositionData(position, buffered, duration ?? Duration.zero),
      );

  Stream<bool> get isPlayingStream =>
      _audioHandler.playbackState.map((state) => state.playing).distinct();

  Stream<MediaItem?> get currentSongStream => _audioHandler.mediaItem;

  Stream<List<MediaItem>> get queueStream => _audioHandler.queue;

  // 【修复】播放单曲
  Future<void> playFromMediaItem(MediaItem item, {int initialIndex = 0}) async {
    // 之前这里写错了 items，应该是 [item]
    await (_audioHandler as MusicHandlerImpl)
        .initSongs(songs: [item], initialIndex: initialIndex);
    await play();
  }

  // 【新增】播放整个列表 (供收藏页/歌单页使用)
  Future<void> playPlaylist(List<MediaItem> items,
      {int initialIndex = 0}) async {
    await (_audioHandler as MusicHandlerImpl)
        .initSongs(songs: items, initialIndex: initialIndex);
  }

  // 队列操作
  Future<void> removeQueueItemAt(int index) =>
      _audioHandler.removeQueueItemAt(index);
  Future<void> moveQueueItem(int oldIndex, int newIndex) =>
      _audioHandler.moveQueueItem(oldIndex, newIndex);
  Future<void> skipToQueueItem(int index) =>
      _audioHandler.skipToQueueItem(index);
// 在 AudioManager 类中添加
  Future<void> addToNext(MediaItem item) =>
      _audioHandler.insertQueueItem(1, item);
  // 基础控制
  Future<void> play() => _audioHandler.play();
  Future<void> pause() => _audioHandler.pause();
  Future<void> seek(Duration position) => _audioHandler.seek(position);
  Future<void> skipToNext() => _audioHandler.skipToNext();
  Future<void> skipToPrevious() => _audioHandler.skipToPrevious();
  Future<void> setVolume(double volume) => _audioHandler.setVolume(volume);
  Stream<double> get volumeStream => _audioHandler.volumeStream;
}
