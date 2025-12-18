import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/core/di/riverpod_bridge.dart';
import 'package:music_app/core/models/position_data.dart';
import 'package:music_app/core/services/audio_manager.dart';

// 1. 播放状态 Provider (Stream)
// 只有当播放/暂停状态改变时，监听这个 Provider 的组件才会重绘
final playerStateProvider = StreamProvider.autoDispose<bool>((ref) {
  final audioManager = ref.watch(audioManagerProvider);
  return audioManager.isPlayingStream;
});

// 2. 当前歌曲元数据 Provider (Stream)
// 只有切歌时，封面和歌名的组件才会重绘
final currentSongProvider = StreamProvider.autoDispose<MediaItem?>((ref) {
  final audioManager = ref.watch(audioManagerProvider);
  return audioManager.currentSongStream;
});

// 3. 进度条 Provider (Stream)
// 这个更新频率极高 (每秒几次)，必须单独隔离，防止导致整个页面重绘
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

// 4. 播放控制器 (Controller/ViewModel)
// 封装用户意图，UI 只管调用这里的方法，不管具体实现
final playerControllerProvider = Provider<PlayerController>((ref) {
  return PlayerController(ref);
});

class PlayerController {
  final Ref _ref;

  PlayerController(this._ref);

  final Logger _logger = getIt<Logger>();

  AudioManager get _manager => _ref.read(audioManagerProvider);

  Future<void> playMediaItem(MediaItem item) async {
    // 实际项目中，这里应该替换当前播放列表，或者插入队列
    await _manager.playFromMediaItem(item);
  }

  void removeFromQueue(int index) {
    _manager.removeQueueItemAt(index);
  }

  // 【新增】排序歌曲
  void reorderQueue(int oldIndex, int newIndex) {
    // ReorderableListView 的 quirk: 如果向下拖拽，newIndex 会多 1，需要修正
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    _manager.moveQueueItem(oldIndex, newIndex);
  }

  // 【新增】点击播放列表中的歌曲
  void skipToQueueItem(int index) {
    _manager.skipToQueueItem(index);
  }

  void play() => _manager.play();
  void pause() => _manager.pause();
  void seek(Duration position) => _manager.seek(position);
  void skipToNext() => _manager.skipToNext(); // 需要在 AudioManager 实现
  void skipToPrevious() => _manager.skipToPrevious(); // 需要在 AudioManager 实现

  void loadTestSong() => _manager.loadTestSong();

  void togglePlay() {
    // 这是一个展示 Riverpod 优势的例子：
    // 我们可以在 Controller 里读取当前状态，决定下一步操作
    final isPlaying = _ref.read(playerStateProvider).value ?? false;
    if (isPlaying) {
      _manager.pause();
    } else {
      _manager.play();
    }
  }

  void setVolume(double value) {
    _manager.setVolume(value);
  }

  Future<void> pickAndPlayLocal() async {
    try {
      // 1. 打开文件选择器
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio, // 限制只选音频
        dialogTitle: 'Select an audio file',
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;

        // 2. 构建 MediaItem
        // 关键点：将本地路径转换为 file:// URI 字符串
        // 因为我们的 AudioManager 统一使用 Uri.parse() 解析 ID
        final localUri = Uri.file(filePath).toString();
        _logger.i("播放本地文件: $localUri"); // 添加日志

        final mediaItem = MediaItem(
          id: localUri,
          title: fileName,
          artist: "Local File",
          album: "My Computer",
          // 本地文件通常没有封面 URL，除非去解析 ID3，这里先留空
          artUri: null,
        );

        // 3. 调用统一播放接口
        await playMediaItem(mediaItem);
      }
    } catch (e) {
      _logger.e("Error picking file", error: e);
    }
  }
}
