import 'package:audio_service/audio_service.dart'; // 系统级音频服务（后台播放/系统控制）
import 'package:just_audio/just_audio.dart'; // 核心音频播放引擎（实际处理音频加载/播放）
import 'package:logger/logger.dart'; // 日志工具（调试/错误追踪）
import 'package:music_app/core/di/injection.dart'; // 依赖注入（获取Logger/SharedPreferences）
import 'package:shared_preferences/shared_preferences.dart'; // 本地轻量存储（持久化音量设置）

// 1. 音频处理器抽象接口（定义核心能力）
/// 音乐播放核心接口，扩展自 AudioService 的 BaseAudioHandler + SeekHandler
/// 设计目的：
/// - 抽象音频播放的核心能力，解耦接口与实现，便于后续替换/扩展
/// - 新增音量控制、队列初始化、队列操作等业务所需的方法
abstract class MusicHandler extends BaseAudioHandler with SeekHandler {
  /// 设置播放音量
  Future<void> setVolume(double volume);

  /// 音量变化流（实时监听音量值）
  Stream<double> get volumeStream;

  /// 初始化播放队列（核心：加载歌曲列表并定位到初始播放位置）
  /// 参数：
  ///   - songs：待播放的媒体项列表（MediaItem 是 AudioService 标准模型）
  ///   - initialIndex：初始播放索引（默认第0首）
  Future<void> initSongs(
      {required List<MediaItem> songs, int initialIndex = 0});

  /// 移除队列中指定位置的歌曲
  @override
  Future<void> removeQueueItemAt(int index);

  /// 移动队列中歌曲的位置（调整播放顺序）
  Future<void> moveQueueItem(int oldIndex, int newIndex);

  /// 跳转到队列中指定位置的歌曲播放
  @override
  Future<void> skipToQueueItem(int index);

  /// 播放进度流（实时获取当前播放位置，如 01:20/03:45 中的 01:20）
  Stream<Duration> get positionStream;

  /// 歌曲时长流（实时获取当前歌曲总时长）
  Stream<Duration?> get durationStream;

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem);
}

// 2. 音频处理器实现类（核心业务逻辑）
/// MusicHandler 接口的具体实现，基于 just_audio 封装
/// 核心依赖：
/// - AudioPlayer：just_audio 的核心播放实例，处理音频加载/播放/暂停等底层操作
/// - BaseAudioHandler：AudioService 提供的基类，负责与系统媒体控制（如通知栏、锁屏控件）同步状态
class MusicHandlerImpl extends BaseAudioHandler
    with SeekHandler
    implements MusicHandler {
  // 底层音频播放引擎实例（just_audio 核心）
  final AudioPlayer _player = AudioPlayer();
  // 日志工具（依赖注入获取，统一日志格式）
  final Logger _logger = getIt<Logger>();
  // 本地存储（依赖注入获取，用于持久化音量设置）
  final SharedPreferences _prefs = getIt<SharedPreferences>();

  // 常量定义：音量设置的存储Key + 默认值
  static const String _volumeKey = 'user_volume_preference'; // SP中存储音量的Key
  static const double _defaultVolume = 0.5; // 默认音量（50%）

  /// 构造函数：初始化时执行 _init 方法，完成基础配置
  MusicHandlerImpl() {
    _init();
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    // 1. 如果当前列表为空，直接初始化
    if (_player.sequence.isEmpty) {
      await initSongs(songs: [mediaItem]);
      return;
    }

    // 2. 计算插入位置
    // 如果 index 是 -1，表示"下一首"
    final currentIndex = _player.currentIndex ?? 0;
    final insertIndex = (index == -1) ? currentIndex + 1 : index;

    // 防止越界
    // 注意：sequence 可能包含 null，所以要判空
    final length = _player.sequence.length;
    final safeIndex = insertIndex.clamp(0, length);

    // 3. 构建 AudioSource
    final audioSource = AudioSource.uri(
      Uri.parse(mediaItem.id),
      tag: mediaItem,
    );

    // 4. 【核心修复】直接调用 player.insertAudioSource
    await _player.insertAudioSource(safeIndex, audioSource);
  }

  /// 初始化核心方法（私有）
  /// 核心流程：
  /// 1. 恢复用户上次的音量设置
  /// 2. 监听队列变化，同步到 AudioService 的 queue 状态
  /// 3. 监听音量变化，自动持久化到本地
  /// 4. 监听播放事件，同步到系统媒体控制状态
  /// 5. 监听播放索引变化，同步当前播放的媒体项
  /// 6. 监听歌曲时长变化，修复 MediaItem 时长为空的问题
  Future<void> _init() async {
    // 1. 恢复用户音量设置（优先读取本地存储，无则用默认值）
    final savedVolume = _prefs.getDouble(_volumeKey) ?? _defaultVolume;
    await _player.setVolume(savedVolume);
    // 2. 监听队列变化（just_audio 的 sequenceStateStream → AudioService 的 queue 状态）
    // sequenceState：just_audio 中的播放队列状态，包含所有音频源
    _player.sequenceStateStream.listen((sequenceState) {
      // 提取音频源中的 MediaItem 标签，转换为 AudioService 识别的队列
      final sequence = sequenceState.effectiveSequence;
      final items = sequence.map((source) => source.tag as MediaItem).toList();
      // 更新 AudioService 的 queue 状态（同步到系统媒体控件）
      queue.add(items);
    });

    // 3. 监听音量变化，自动持久化到本地（用户调整音量后保存）
    _player.volumeStream.listen((volume) {
      _prefs.setDouble(_volumeKey, volume);
    });

    // 4. 监听播放事件（如播放/暂停/缓冲），同步到系统媒体控制状态
    _player.playbackEventStream.listen(
      _broadcastState, // 核心：将 just_audio 事件转换为 AudioService 状态
      onError: (Object e, StackTrace stackTrace) {
        _logger.e("AudioPlayer 内部播放事件流错误", error: e, stackTrace: stackTrace);
      },
    );

    // 5. 监听播放索引变化（切换歌曲时），同步当前播放的 MediaItem
    _player.currentIndexStream.listen((index) {
      if (index != null &&
          queue.value.isNotEmpty &&
          index < queue.value.length) {
        // 更新 AudioService 的 mediaItem 状态（系统通知栏显示当前歌曲信息）
        mediaItem.add(queue.value[index]);
      }
    });

    // 6. 监听歌曲时长变化（修复 MediaItem 初始时长为空的问题）
    // 原因：初始传入的 MediaItem 可能没有时长，需等音频加载后补全
    _player.durationStream.listen((duration) {
      if (duration != null) {
        _logger.d("🔍 [AudioHandler] 捕获到底层时长: $duration");

        // ① 更新队列中对应歌曲的时长
        final index = _player.currentIndex;
        final currentQueue = queue.value;
        if (index != null &&
            currentQueue.isNotEmpty &&
            index < currentQueue.length) {
          final oldItem = currentQueue[index];
          final newItem = oldItem.copyWith(duration: duration); // 补全时长
          final newQueue = List<MediaItem>.from(currentQueue);
          newQueue[index] = newItem;
          queue.add(newQueue); // 同步更新队列
        }

        // ② 更新当前播放的 MediaItem 时长（确保系统通知栏显示正确时长）
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

  /// 播放进度流：暴露 just_audio 的 positionStream
  @override
  Stream<Duration> get positionStream => _player.positionStream;

  /// 歌曲时长流：暴露 just_audio 的 durationStream
  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  /// 核心：将 just_audio 的播放事件转换为 AudioService 状态
  /// 目的：让系统媒体控件（通知栏/锁屏）感知播放状态，支持系统级控制（如暂停/下一首）
  void _broadcastState(PlaybackEvent event) {
    playbackState.add(
      playbackState.value.copyWith(
        // 系统媒体控件显示的操作按钮（上一首、播放/暂停、下一首）
        controls: [
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        // 系统支持的操作（进度条拖动、快进、快退）
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        // Android 通知栏紧凑布局的按钮索引（对应 controls 的顺序）
        androidCompactActionIndices: const [0, 1, 2],
        // 播放状态映射（just_audio → AudioService）
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        // 当前是否正在播放
        playing: _player.playing,
        // 当前播放进度
        updatePosition: _player.position,
        // 缓冲进度（用于显示缓冲条）
        bufferedPosition: _player.bufferedPosition,
        // 播放速度（1.0 为正常速度）
        speed: _player.speed,
        // 当前播放队列索引
        queueIndex: event.currentIndex,
      ),
    );
  }

  // ====================== 基础音频控制方法（实现接口） ======================
  /// 播放：调用 just_audio 的 play 方法
  @override
  Future<void> play() => _player.play();

  /// 暂停：调用 just_audio 的 pause 方法
  @override
  Future<void> pause() => _player.pause();

  /// 拖动进度：调用 just_audio 的 seek 方法（如从 01:00 拖到 02:30）
  @override
  Future<void> seek(Duration position) => _player.seek(position);

  /// 停止播放：先停止底层播放器，再调用父类 stop（同步系统状态）
  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  /// 上一首：调用 just_audio 的 seekToPrevious 方法
  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  /// 下一首：调用 just_audio 的 seekToNext 方法
  @override
  Future<void> skipToNext() => _player.seekToNext();

  /// 设置音量：调用 just_audio 的 setVolume 方法（0.0-1.0）
  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  /// 音量流：暴露 just_audio 的 volumeStream（实时监听音量变化）
  @override
  Stream<double> get volumeStream => _player.volumeStream;

  // ====================== 播放队列操作方法（实现接口） ======================
  /// 跳转到队列中指定索引的歌曲播放
  /// 逻辑：校验索引合法性 → 定位到指定歌曲开头 → 自动播放
  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return; // 索引越界则返回
    await _player.seek(Duration.zero, index: index); // 定位到歌曲开头
    play(); // 自动播放
  }

  /// 移除队列中指定索引的歌曲
  @override
  Future<void> removeQueueItemAt(int index) async {
    await _player.removeAudioSourceAt(index); // 调用 just_audio 移除音频源
  }

  /// 移动队列中歌曲的位置（调整播放顺序）
  @override
  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    await _player.moveAudioSource(oldIndex, newIndex); // 调用 just_audio 移动音频源
  }

  // ====================== 初始化播放队列（核心业务方法） ======================
  /// 初始化播放队列并开始播放
  /// 核心流程：
  /// 1. 同步队列/当前歌曲状态到 AudioService
  /// 2. 将 MediaItem 转换为 just_audio 可识别的 AudioSource
  /// 3. 加载音频源到播放器
  /// 4. 恢复音量 + 重置播放进度
  /// 5. 自动开始播放
  @override
  Future<void> initSongs({
    required List<MediaItem> songs,
    int initialIndex = 0,
  }) async {
    try {
      // 1. 同步状态到 AudioService（先更新队列和当前歌曲，避免系统控件显示延迟）
      queue.add(songs);
      mediaItem.add(songs[initialIndex]);

      // 2. 转换 MediaItem → AudioSource（just_audio 只能播放 AudioSource）
      final audioSources = songs.map((item) {
        _logger.w("🎵 准备播放 URL: ${item.id}");
        return AudioSource.uri(
          Uri.parse(item.id), // item.id 是歌曲的播放地址（URL/本地路径）
          tag: item, // 携带 MediaItem 元数据（歌名/歌手/封面等）
        );
      }).toList();

      // 3. 加载音频源到播放器，并定位到初始索引
      await _player.setAudioSources(audioSources, initialIndex: initialIndex);

      // 4. 恢复音量（确保音量设置生效）+ 重置播放进度到开头
      await _player.setVolume(_player.volume);
      await _player.seek(Duration.zero);

      // 5. 自动开始播放
      play();
    } catch (e, stack) {
      // 捕获加载失败异常（如地址无效、网络错误），记录日志
      _logger.e("❌ 加载音频源失败", error: e, stackTrace: stack);
    }
  }
}
