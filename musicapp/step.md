这是一个非常具体的落地执行计划。我们将按照 **“基础设施 -> 核心音频引擎 -> UI与状态绑定 -> 数据接入”** 的顺序进行。

这是企业级开发的标准路径：先搭建骨架，再攻克最难的核心（音频服务），最后才是画界面和接接口。

---

### 第一阶段：基础设施搭建 (Infrastructure Setup)

**目标**：建立项目骨架、配置依赖注入、路由和基础库。

1. **初始化项目与目录**

   * 创建 Flutter 项目。
   * 按照 `Clean Architecture` 创建目录结构：
     ```text
     lib/
       ├── core/ (di, network, theme, utils)
       ├── features/ (music_player, auth, home)
       └── main.dart
     ```
2. **引入核心依赖 (`pubspec.yaml`)**

   * **架构:** `get_it`, `injectable`, `flutter_bloc`, `equatable`, `go_router`
   * **音频:** `just_audio`, `audio_service`, `just_audio_background` (如果不需要复杂的自定义Service逻辑，这个库更简单，但企业级推荐自己实现 AudioHandler)
   * **网络:** `dio`, `retrofit`, `json_annotation`
   * **UI/Utils:** `cached_network_image`, `rxdart` (用于合并流)
3. **配置依赖注入 (DI)**

   * 在 `lib/core/di/injection.dart` 中配置 `GetIt`。
   * 创建 `AppModule` 类，注册 `AudioPlayer` 和 `Dio` 为单例。
4. **配置路由 (GoRouter)**

   * 在 `lib/core/router` 中配置路由，定义 `ShellRoute` (用于保持底部 MiniPlayer 在页面切换时不消失)。

---

### 第二阶段：核心音频服务 (Audio Service Layer) - **最关键步骤**

**目标**：实现后台播放、锁屏控制，与 UI 线程解耦。

1. **自定义 AudioHandler**

   * 这是 `audio_service` 的核心。创建一个类 `MyAudioHandler` 继承自 `BaseAudioHandler`。
   * **实现:** 内部持有 `just_audio` 的 `AudioPlayer` 实例。
   * **映射:** 将 `AudioPlayer` 的事件（播放结束、缓冲中）映射为 `AudioService` 的状态（通知栏更新）。

   ```dart
   // features/music_player/services/audio_handler.dart
   class MyAudioHandler extends BaseAudioHandler with SeekHandler {
     final _player = AudioPlayer();

     Future<void> init() async {
       // 监听播放器事件，更新系统通知状态
       _player.playbackEventStream.listen((PlaybackEvent event) {
         final playing = _player.playing;
         playbackState.add(playbackState.value.copyWith(
           controls: [
             MediaControl.skipToPrevious,
             playing ? MediaControl.pause : MediaControl.play,
             MediaControl.skipToNext,
           ],
           systemActions: const {MediaAction.seek},
           processingState: const {
             ProcessingState.idle: AudioProcessingState.idle,
             ProcessingState.loading: AudioProcessingState.loading,
             ProcessingState.buffering: AudioProcessingState.buffering,
             ProcessingState.ready: AudioProcessingState.ready,
             ProcessingState.completed: AudioProcessingState.completed,
           }[_player.processingState]!,
           playing: playing,
           updatePosition: _player.position,
           bufferedPosition: _player.bufferedPosition,
         ));
       });
     }

     @override
     Future<void> play() => _player.play();

     @override
     Future<void> pause() => _player.pause();

     // ... 实现 seek, skip, addQueueItem 等方法
   }
   ```
2. **创建 AudioManager (门面模式)**

   * UI 层不直接调用 `AudioHandler`，而是通过 `AudioManager`。
   * `AudioManager` 负责将 `AudioHandler` 的各种 Stream（进度、当前歌曲、播放列表）合并或转换为 UI 易用的 Stream。
   * 使用 `RxDart` 的 `CombineLatestStream` 组合“当前播放进度”和“总时长”。
3. **原生配置 (OS Config)**

   * **Android (`AndroidManifest.xml`):** 添加 `WAKE_LOCK` 和 `FOREGROUND_SERVICE` 权限。声明 `AudioService` 的 receiver。
   * **iOS (`Info.plist`):** 打开 `UIBackgroundModes` -> `audio`。

---

### 第三阶段：状态管理与 BLoC (State Management)

**目标**：连接音频服务与 UI，实现单向数据流。

1. **定义 PlayerState**

   * 使用 `freezed` 或 `equatable`。
   * 状态包含：`MediaItem? currentSong`, `bool isPlaying`, `Duration position`, `Duration totalDuration`, `ProcessingState status`。
2. **实现 PlayerBloc**

   * **初始化:** 在构造函数中 `listen` `AudioManager` 暴露出来的 Streams。
   * **事件处理:**
     * `PlayEvent`: 调用 `audioManager.play()`
     * `SeekEvent`: 调用 `audioManager.seek()`
     * `OnProgressUpdated`: (由 Stream 触发) `emit` 新的状态。

   ```dart
   // 伪代码示例
   class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
     final AudioManager _audioManager;

     PlayerBloc(this._audioManager) : super(PlayerState.initial()) {
       // 订阅音频服务的状态变化
       _audioManager.currentSongStream.listen((song) {
           add(CurrentSongChanged(song));
       });

       on<PlayToggled>((event, emit) {
           if (state.isPlaying) _audioManager.pause();
           else _audioManager.play();
       });
     }
   }
   ```

---

### 第四阶段：UI 实现 (Presentation Layer)

**目标**：构建现代化的播放器界面。

1. **全局 MiniPlayer**

   * 这是一个始终吸底的 Widget。
   * 使用 `BlocBuilder<PlayerBloc, PlayerState>` 监听状态。
   * 点击 MiniPlayer 通过 `context.push('/player')` 打开全屏页。
2. **全屏播放页 (PlayerScreen)**

   * **背景:** 使用 `Blur` 效果处理当前专辑封面作为背景。
   * **进度条:** 使用 `AudioVideoProgressBar` (来自 `audio_video_progress_bar` 库，非常好用)。
   * **封面:** 使用 `Hero` 动画，从 MiniPlayer 放大到全屏页。
3. **歌词页 (Lyrics - 可选)**

   * 使用 `StreamBuilder` 监听进度，结合 `.lrc` 解析器实现滚动。

---

### 第五阶段：数据层与网络 (Data & Network)

**目标**：对接 Aspire 后端，获取真实数据。

1. **定义 DTOs (Data Transfer Objects)**

   * 创建 `SongDto`, `PlaylistDto`。使用 `json_serializable`。
2. **Retrofit 接口定义**

   * 定义 `MusicApi` 接口。

   ```dart
   @RestApi()
   abstract class MusicApi {
     @GET("/songs/trending")
     Future<List<SongDto>> getTrendingSongs();

     @GET("/songs/{id}/url")
     Future<String> getSongUrl(@Path("id") String id);
   }
   ```
3. **Repository 实现**

   * `MusicRepositoryImpl` 调用 `MusicApi`。
   * **重要:** 这里进行数据转换，将 `SongDto` (后端数据) 转换为 `MediaItem` (audio_service 需要的标准格式)。
4. **集成真实播放**

   * 当用户点击列表中的歌曲时：
     1. UI 触发 BLoC 事件 `PlayRequested(songId)`。
     2. BLoC 调用 Repository 获取音频 URL（后端可能返回 S3 的签名 URL）。
     3. BLoC 将 URL 和 Metadata 传给 `AudioManager`。
     4. `AudioManager` 将资源放入 `AudioHandler` 队列并开始播放。

---

### 第六阶段：优化与完善 (Optimization)

1. **缓存策略**

   * 引入 `flutter_cache_manager` 缓存封面图。
   * 利用 `just_audio` 的 `LockCachingAudioSource` 实现音频边下边播并缓存到文件系统。
2. **错误处理**

   * 给 Dio 添加 Interceptor，统一处理网络错误。
   * 在 UI 层使用 `BlocListener` 监听错误状态，弹出 `SnackBar`。
3. **平台适配**

   * 适配 iOS 的刘海屏（Safe Area）。
   * 处理 Android 的返回键逻辑（收起全屏播放页而不是退出 App）。

---

### 总结：必须严格遵守的顺序

不要一上来就写 UI！

1. **配置** (Config & DI)
2. **音频核心** (AudioHandler) -> 哪怕没有 UI，写死代码能播放声音才算过关。
3. **逻辑** (BLoC)
4. **UI** (Widgets)
5. **数据** (API)

这样开发，你的 App 即使只有“播放”一个按钮，它也是企业级架构，稳定且健壮。
