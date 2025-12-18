// 导入 audio_service 核心库
import 'package:audio_service/audio_service.dart';
// 导入 just_audio 库
import 'package:just_audio/just_audio.dart';
// 导入 Logger 库
import 'package:logger/logger.dart';
// 导入依赖注入工具
import 'package:music_app/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. 抽象接口定义
abstract class MusicHandler extends BaseAudioHandler with SeekHandler {
  Future<void> setVolume(double volume);
  Stream<double> get volumeStream;
  Future<void> initSongs(
      {required List<MediaItem> songs, int initialIndex = 0});

  @override
  Future<void> removeQueueItemAt(int index);
  Future<void> moveQueueItem(int oldIndex, int newIndex);
  @override
  Future<void> skipToQueueItem(int index);
}

// 2. 接口实现类
class MusicHandlerImpl extends BaseAudioHandler
    with SeekHandler
    implements MusicHandler {
  final AudioPlayer _player = AudioPlayer();
  final Logger _logger = getIt<Logger>();
  final SharedPreferences _prefs = getIt<SharedPreferences>();

  // 定义存储 Key 和默认值
  static const String _volumeKey = 'user_volume_preference';
  static const double _defaultVolume = 0.5;

  MusicHandlerImpl() {
    _init();
  }

  Future<void> _init() async {
    // 恢复音量
    final savedVolume = _prefs.getDouble(_volumeKey) ?? _defaultVolume;
    await _player.setVolume(savedVolume);
    _logger.i("🔊 恢复用户音量设置: $savedVolume");

    // 监听队列变化
    _player.sequenceStateStream.listen((sequenceState) {
      final sequence = sequenceState.effectiveSequence;
      final items = sequence.map((source) => source.tag as MediaItem).toList();
      queue.add(items);
    });

    // 监听并保存音量
    _player.volumeStream.listen((volume) {
      _prefs.setDouble(_volumeKey, volume);
    });

    // 监听播放事件
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object e, StackTrace stackTrace) {
        _logger.e("AudioPlayer 内部播放事件流错误", error: e, stackTrace: stackTrace);
      },
    );

    // 监听索引变化
    _player.currentIndexStream.listen((index) {
      if (index != null &&
          queue.value.isNotEmpty &&
          index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    // 监听播放结束
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
      }
    });

    // 监听时长更新
    _player.durationStream.listen((duration) {
      if (duration != null) {
        _logger.d("🔍 [AudioHandler] 捕获到底层时长: $duration");

        final index = _player.currentIndex;
        final currentQueue = queue.value;
        if (index != null &&
            currentQueue.isNotEmpty &&
            index < currentQueue.length) {
          final oldItem = currentQueue[index];
          final newItem = oldItem.copyWith(duration: duration);
          final newQueue = List<MediaItem>.from(currentQueue);
          newQueue[index] = newItem;
          queue.add(newQueue);
        }

        final currentItem = mediaItem.value;
        if (currentItem != null) {
          if (currentItem.duration != duration) {
            mediaItem.add(currentItem.copyWith(duration: duration));
            _logger.i("✅ [AudioHandler] 强制更新当前 MediaItem 时长成功！");
          }
        } else {
          _logger.w("⚠️ [AudioHandler] 依然无法更新：当前 MediaItem 为空");
        }
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  // ====================== 基础音频方法 ======================
  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();
  @override
  Future<void> skipToNext() => _player.seekToNext();
  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);
  @override
  Stream<double> get volumeStream => _player.volumeStream;

  // ====================== 队列操作 ======================
  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _player.seek(Duration.zero, index: index);
    play();
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    await _player.removeAudioSourceAt(index);
  }

  @override
  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    await _player.moveAudioSource(oldIndex, newIndex);
  }

  // ====================== 初始化 ======================
  @override
  Future<void> initSongs({
    required List<MediaItem> songs,
    int initialIndex = 0,
  }) async {
    try {
      // 1. 先同步状态
      queue.add(songs);
      mediaItem.add(songs[initialIndex]);

      // 2. 构建音频源
      final audioSources = songs.map((item) {
        return AudioSource.uri(
          Uri.parse(item.id),
          tag: item,
        );
      }).toList();

      // 3. 加载
      await _player.setAudioSources(audioSources, initialIndex: initialIndex);

      // 4. 恢复音量并重置进度
      await _player.setVolume(_player.volume);
      await _player.seek(Duration.zero);

      // 5. 播放
      play();
    } catch (e, stack) {
      _logger.e("❌ 加载音频源失败", error: e, stackTrace: stack);
    }
  }
}
