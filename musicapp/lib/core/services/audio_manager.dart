// 导入 audio_service 核心库：提供音频后台播放、系统媒体控制的基础能力
import 'package:audio_service/audio_service.dart';
// 导入 injectable 库：用于依赖注入（DI），提供 @singleton 等注解，管理类的实例生命周期
import 'package:injectable/injectable.dart';
// 导入自定义进度数据模型：封装「当前播放进度、缓冲进度、总时长」三个维度的进度数据
import 'package:music_app/core/models/position_data.dart';
// 导入音频处理器：引用之前定义的 MusicHandler 抽象接口和 MusicHandlerImpl 实现类
import 'package:music_app/core/services/audio_handler.dart';
// 导入 rxdart 库：扩展 Dart 原生 Stream，提供多流组合、去重等增强能力（核心是 combineLatest3）
import 'package:rxdart/rxdart.dart';

/// 音频管理类：作为 UI 层与底层音频处理器（MusicHandler）之间的「中间层」
/// 核心作用：
/// 1. 封装底层音频操作，对外提供简洁统一的 API（UI 层无需关心底层实现）
/// 2. 组合关键数据流（进度、播放状态、当前歌曲），简化 UI 层监听逻辑
/// 3. 单例管理（@singleton），保证全局音频状态一致
@singleton // injectable 注解：标记此类为单例，由 DI 容器创建和管理，全局唯一实例
class AudioManager {
  /// 底层音频处理器实例：通过构造函数注入（DI 容器自动传入 MusicHandlerImpl 实例）
  /// 依赖抽象接口（MusicHandler）而非具体实现，符合「依赖倒置原则」
  final MusicHandler _audioHandler;

  /// 构造函数：接收 DI 注入的 MusicHandler 实例
  // ignore: unintended_html_in_doc_comment
  /// 外部无法手动 new，只能通过 DI 容器（getIt<AudioManager>()）获取实例
  AudioManager(this._audioHandler);

  // --- 对外暴露的核心数据流（UI 层只需监听这些流，无需关心底层拼接逻辑） ---

  /// 1. 进度组合数据流：整合「当前播放进度、缓冲进度、歌曲总时长」为统一的 PositionData 流
  /// UI 层监听此流即可实时更新进度条、缓冲进度、时长显示等组件
  Stream<PositionData> get positionDataStream =>
      // Rx.combineLatest3：组合 3 个独立的 Stream，任意一个流有新值时，触发组合计算
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        // 流1：AudioService 全局播放进度（已播放时长）
        AudioService.position,
        // 流2：音频处理器的缓冲进度（从 playbackState 中提取 bufferedPosition）
        _audioHandler.playbackState.map((state) => state.bufferedPosition),
        // 流3：当前播放歌曲的总时长（MediaItem 可能为 null，默认返回 0 时长）
        _audioHandler.mediaItem.map((item) => item?.duration ?? Duration.zero),
        // 组合逻辑：将 3 个流的最新值封装为自定义的 PositionData 模型
        (position, buffered, duration) =>
            PositionData(position, buffered, duration ?? Duration.zero),
      );

  /// 2. 播放状态流：当前是否正在播放（去重处理，避免 UI 重复刷新）
  Stream<bool> get isPlayingStream =>
      // 从 playbackState 提取 playing 状态，distinct() 过滤连续重复的值
      // 例如：连续多次推送 true 时，仅第一次触发 UI 更新，优化性能
      _audioHandler.playbackState.map((state) => state.playing).distinct();

  /// 3. 当前播放歌曲流：实时推送当前播放的 MediaItem（包含歌曲名、封面、时长等元数据）
  /// UI 层监听此流更新歌曲信息展示（如标题、歌手、封面图）
  Stream<MediaItem?> get currentSongStream => _audioHandler.mediaItem;

  // --- 封装底层音频操作方法（对外提供简洁 API，屏蔽底层细节） ---

  /// 播放单个媒体项（单曲播放）
  /// [item]：要播放的 MediaItem（包含音频地址、元数据等）
  Future<void> playFromMediaItem(MediaItem item) async {
    // 类型转换说明：
    // - _audioHandler 注入的是 MusicHandlerImpl 实例（DI 配置保证）
    // - 抽象接口 MusicHandler 定义了 initSongs 方法，此处转换为实现类是安全的
    // - 调用 initSongs 初始化单曲列表（songs 传单元素列表）
    await (_audioHandler as MusicHandlerImpl).initSongs(songs: [item]);
    // 初始化完成后，立即触发播放
    await play();
  }

  Stream<List<MediaItem>> get queueStream => _audioHandler.queue;

  // 【新增】队列操作
  Future<void> removeQueueItemAt(int index) =>
      _audioHandler.removeQueueItemAt(index);

  Future<void> moveQueueItem(int oldIndex, int newIndex) =>
      _audioHandler.moveQueueItem(oldIndex, newIndex);

  Future<void> skipToQueueItem(int index) =>
      _audioHandler.skipToQueueItem(index);

  /// 播放：调用底层音频处理器的 play 方法
  Future<void> play() => _audioHandler.play();

  /// 暂停：调用底层音频处理器的 pause 方法
  Future<void> pause() => _audioHandler.pause();

  /// 进度拖拽：跳转到指定播放位置（如用户拖动进度条）
  /// [position]：目标播放位置（Duration 类型，如 Duration(seconds: 30)）
  Future<void> seek(Duration position) => _audioHandler.seek(position);

  /// 音量变化流：暴露底层音频处理器的音量流，UI 层监听更新音量控件
  Stream<double> get volumeStream => _audioHandler.volumeStream;

  /// 下一曲：调用底层音频处理器的 skipToNext 方法
  Future<void> skipToNext() => _audioHandler.skipToNext();

  /// 上一曲：调用底层音频处理器的 skipToPrevious 方法
  Future<void> skipToPrevious() => _audioHandler.skipToPrevious();

  /// 设置音量：调用底层音频处理器的 setVolume 方法
  /// [volume]：音量值（0.0~1.0）
  Future<void> setVolume(double volume) => _audioHandler.setVolume(volume);

  // --- 测试专用方法：快速加载测试歌曲，验证音频播放功能 ---
  Future<void> loadTestSong() async {
    // 构建测试用的 MediaItem：包含网络音频地址、元数据、时长、封面等
    final song = MediaItem(
      id: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', // 测试音频 URL
      album: 'Test Album', // 专辑名
      title: 'SoundHelix Song 1', // 歌曲名
      artist: 'SoundHelix', // 歌手名
      duration: const Duration(minutes: 6, seconds: 12), // 歌曲总时长（手动指定）
      artUri: Uri.parse('https://via.placeholder.com/300'), // 封面占位图 URL
    );
    // 类型转换后调用 initSongs，加载测试歌曲列表（单首）
    await (_audioHandler as MusicHandlerImpl).initSongs(songs: [song]);
  }
}
