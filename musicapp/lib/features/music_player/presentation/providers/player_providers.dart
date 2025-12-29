import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/core/di/riverpod_bridge.dart';
import 'package:music_app/core/models/position_data.dart';
import 'package:music_app/core/services/audio_manager.dart';
import 'package:music_app/features/music_player/presentation/providers/lyrics_provider.dart';

// 1. 播放状态 Provider
final playerStateProvider = StreamProvider.autoDispose<bool>((ref) {
  final audioManager = ref.watch(audioManagerProvider);
  return audioManager.isPlayingStream;
});

// 2. 当前歌曲元数据 Provider
final currentSongProvider = StreamProvider.autoDispose<MediaItem?>((ref) {
  final audioManager = ref.watch(audioManagerProvider);
  return audioManager.currentSongStream;
});

// 3. 进度条 Provider
final progressProvider = StreamProvider.autoDispose<PositionData>((ref) {
  final audioManager = ref.watch(audioManagerProvider);
  return audioManager.positionDataStream;
});

final volumeProvider = StreamProvider.autoDispose<double>((ref) {
  final audioManager = ref.watch(audioManagerProvider);
  return audioManager.volumeStream;
});

final queueProvider = StreamProvider.autoDispose<List<MediaItem>>((ref) {
  final audioManager = ref.watch(audioManagerProvider);
  return audioManager.queueStream;
});

// 【注意】这里不再定义 lyricsProvider 和 currentLyricIndexProvider
// 它们已经在 lyrics_provider.dart 中定义了

// 4. 播放控制器
final playerControllerProvider = Provider<PlayerController>((ref) {
  return PlayerController(ref);
});

class PlayerController {
  final Ref _ref;
  final Logger _logger = getIt<Logger>();

  PlayerController(this._ref);

  AudioManager get _manager => _ref.read(audioManagerProvider);

  Future<void> playMediaItem(MediaItem item) async {
    await _manager.playFromMediaItem(item);
  }

  void playNext(MediaItem item) {
    _manager.addToNext(item);
  }

  void removeFromQueue(int index) => _manager.removeQueueItemAt(index);

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    _manager.moveQueueItem(oldIndex, newIndex);
  }

  void skipToQueueItem(int index) => _manager.skipToQueueItem(index);

  void play() => _manager.play();
  void pause() => _manager.pause();
  void seek(Duration position) => _manager.seek(position);
  void skipToNext() => _manager.skipToNext();
  void skipToPrevious() => _manager.skipToPrevious();

  void togglePlay() {
    final isPlaying = _ref.read(playerStateProvider).value ?? false;
    isPlaying ? _manager.pause() : _manager.play();
  }

  void setVolume(double value) => _manager.setVolume(value);

  // 播放整个列表
  Future<void> playPlaylist(List<MediaItem> items, {int index = 0}) async {
    await _manager.playPlaylist(items, initialIndex: index);
  }

  // 播放本地文件
  Future<void> pickAndPlayLocal() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        dialogTitle: 'Select an audio file',
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        final localUri = Uri.file(filePath).toString();

        _logger.i("播放本地文件: $localUri");

        final mediaItem = MediaItem(
          id: localUri,
          title: fileName,
          artist: "Local File",
          album: "My Computer",
          artUri: null,
        );

        await playMediaItem(mediaItem);
      }
    } catch (e) {
      _logger.e("Error picking file", error: e);
    }
  }

  // 【核心修复】加载本地歌词
  // 现在这行代码不会报错了，因为 lyricsProvider 是从 lyrics_provider.dart 引入的 StateNotifierProvider
  Future<void> pickAndLoadLrc() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['lrc', 'txt'],
        dialogTitle: 'Select a lyrics file (.lrc)',
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        // 这里的 notifier 现在可以被正确识别了
        _ref.read(lyricsProvider.notifier).setLyrics(content);

        _logger.i("本地歌词加载成功");
      }
    } catch (e) {
      _logger.e("加载歌词失败", error: e);
    }
  }
}
