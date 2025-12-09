
为了构建一个**企业级**的 Flutter 音乐播放器，我们需要超越简单的 MVC 模式，采用 **Clean Architecture（整洁架构）** 结合 **Feature-First（按功能分包）** 的目录结构。这种架构能确保代码的可测试性、可维护性，并且能够应对复杂的音频状态管理。

以下是详细的前端架构设计方案：

---

### 1. 核心架构模式：Clean Architecture + BLoC

我们将应用分为三层：**Data (数据层)**, **Domain (领域层)**, **Presentation (表现层)**。

#### 依赖规则

`Presentation` -> `Domain` <- `Data`

* **Domain 层**是核心，不依赖任何 UI 库或数据实现库（纯 Dart 代码）。
* **Presentation 层**和 **Data 层**都依赖于 Domain 层。

---

### 2. 详细分层设计

#### A. Domain Layer (领域层 - 业务核心)

这是应用的“大脑”，定义了业务逻辑和数据契约。

* **Entities (实体):** 业务对象，如 `Song`, `Playlist`, `Artist`。不包含 `toJson/fromJson` 逻辑。
* **Repositories (接口):** 定义数据操作的抽象接口，例如 `SongRepository`。**注意：这里只写接口（Interface/abstract class）。**
* **Use Cases (用例):** 封装单一的业务动作。例如：`PlaySongUseCase`, `ToggleLikeUseCase`, `SyncOfflineMusicUseCase`。这使得业务逻辑在 UI 中复用变得非常容易。

#### B. Data Layer (数据层 - 基础设施)

这是应用的“四肢”，负责数据的获取和持久化。

* **Models:** `Entities` 的子类或包装类，包含 JSON 序列化逻辑 (`json_serializable`) 和数据库映射 (`isar` / `hive`)。
* **Data Sources:**
  * `RemoteDataSource`: 负责调用后端 Aspire API (Retrofit/Dio)。
  * `LocalDataSource`: 负责读取本地数据库 (Isar) 或缓存。
* **Repository Implementation:** 实现 Domain 层的接口。负责决策数据策略（例如：优先读缓存，缓存过期再请求网络）。

#### C. Presentation Layer (表现层 - UI)

这是应用的“脸”，负责渲染和交互。

* **State Management (BLoC):** 接收 UI 事件 (Events)，调用 UseCase，根据结果发射状态 (States)。
* **Widgets:** 可复用的 UI 组件（如播放条、封面卡片）。
* **Pages/Screens:** 具体的页面。

---

### 3. 音频核心架构 (The Audio Service Layer)

音乐播放器最特殊的地方在于：**播放状态必须独立于 UI 生命周期**。即使用户退出了 UI 页面，音乐在后台（Android Service / iOS AudioSession）依然在播放。

我们需要构建一个独立的 **AudioHandler**。

#### 架构图解

```mermaid
graph TD
    UI[Flutter UI Widgets] <--> BLoC[PlayerBloc]
    BLoC <--> |Streams/Methods| Manager[AudioManager (Singleton)]
  
    subgraph "Audio Core (Background Isolate)"
        Manager <--> AudioService[audio_service Lib]
        AudioService <--> JustAudio[just_audio Player]
    end
  
    JustAudio <--> |M3U8 Stream| Network
    JustAudio <--> |File| Cache[Local Cache Manager]
```

* **AudioManager:** 一个单例（Singleton）服务，封装了 `audio_service` 和 `just_audio`。它向 BLoC 暴露 Stream（如 `positionStream`, `playerStateStream`, `currentSongStream`）。
* **Service Isolation:** 确保音频控制逻辑不写在 UI 代码里，而是通过 BLoC 发送指令（Play, Pause, Seek）。

---

### 4. 项目目录结构 (Feature-First)

企业级项目推荐按功能模块划分，而不是按文件类型划分。

```text
lib/
├── core/                       # 核心共享模块
│   ├── config/                 # 环境变量、主题配置
│   ├── di/                     # 依赖注入 (GetIt)
│   ├── network/                # Dio 封装, Interceptors (Token 刷新)
│   ├── errors/                 # 统一异常处理 (Failures)
│   └── utils/                  # 工具类 (时间格式化等)
├── features/                   # 业务功能模块
│   ├── auth/                   # 认证模块 (登录/注册)
│   ├── music_player/           # 播放器核心模块
│   │   ├── data/
│   │   │   ├── models/         # SongModel, PlaylistModel
│   │   │   ├── datasources/    # MusicRemoteDataSource
│   │   │   └── repositories/   # MusicRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/       # Song
│   │   │   ├── repositories/   # MusicRepository (Interface)
│   │   │   └── usecases/       # PlayStreamUseCase, AddToQueueUseCase
│   │   ├── presentation/
│   │   │   ├── bloc/           # PlayerBloc
│   │   │   ├── pages/          # PlayerScreen, MiniPlayer
│   │   │   └── widgets/        # ProgressBar, PlayButton
│   │   └── services/           # AudioHandler 具体实现
│   ├── library/                # 用户库 (我的收藏/本地音乐)
│   └── search/                 # 搜索模块
├── main.dart
└── app.dart
```

---

### 5. 关键技术栈选型

| 模块                 | 库/技术                     | 原因                                                               |
| :------------------- | :-------------------------- | :----------------------------------------------------------------- |
| **音频内核**   | `just_audio`              | 功能最强，支持 HLS (m3u8)、缓存、无缝切歌。                        |
| **后台服务**   | `audio_service`           | 处理锁屏控制、通知栏、耳机线控、Android Auto/CarPlay。             |
| **状态管理**   | `flutter_bloc`            | 严格的数据流，适合复杂的播放状态同步。                             |
| **网络请求**   | `dio` + `retrofit`      | 强大的拦截器支持（处理 JWT Refresh Token），代码生成减少样板代码。 |
| **依赖注入**   | `get_it` + `injectable` | 解耦各层，方便单元测试。                                           |
| **本地数据库** | `isar`                    | 高性能 NoSQL，查询速度快，适合存储成千上万首歌曲元数据。           |
| **路由**       | `go_router`               | 支持声明式路由，处理 Deep Link（分享歌曲链接直接打开 App）。       |
| **图片加载**   | `cached_network_image`    | 自动缓存封面图，优化列表滚动性能。                                 |
| **UI 动效**    | `animations`              | 页面切换流畅度。                                                   |

---

### 6. 企业级难点解决方案

#### A. 统一错误处理与网络拦截

在 `core/network` 中配置 Dio Interceptor。当后端 Aspire 返回 401 时，自动调用 Identity Service 的 Refresh Token 接口，拿到新 Token 后重试原请求。如果 Refresh 失败，则强制登出并在 UI 层弹出登录页。

#### B. 离线缓存策略 (Hybrid Cache)

为了达到极致体验，采用三级缓存：

1. **内存缓存:** 当前播放列表的 Metadata。
2. **磁盘 LRU 缓存 (Media):** 使用 `just_audio` 的 `LockCachingAudioSource`。播放时自动将流媒体缓存到文件系统，下次播放直接读文件。
3. **数据库缓存 (Metadata):** 所有的 API 请求（如歌单列表）先存入 Isar。
   * *策略:* `Stale-While-Revalidate`。先立即显示数据库内容（即使是旧的），后台静默请求 API，数据回来后刷新 UI。

#### C. 大列表性能优化

歌单可能包含数千首歌。

* 使用 `ListView.builder`。
* 每个 List Item 是一个 `const` Widget。
* 使用 `RepaintBoundary` 包裹复杂的 Item，防止全屏重绘。
* 使用 `Select` (BlocSelector) 仅监听当前 Item 需要的数据变化（例如：只有当前播放的歌曲 Item 需要显示动态波形图，其他 Item 不重绘）。

---

### 7. 代码实现示例

#### 依赖注入配置 (dependency_injection.dart)

```dart
final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();

@module
abstract class RegisterModule {
  // 注册全局单例的 AudioPlayer
  @singleton
  AudioPlayer get audioPlayer => AudioPlayer();
  
  // 注册 Dio
  @singleton
  Dio get dio => DioBase().dio; // 包含拦截器配置
}
```

#### UseCase 定义 (play_song_usecase.dart)

```dart
class PlaySongUseCase {
  final MusicRepository repository;
  final AudioManager audioManager; // 封装好的音频服务

  PlaySongUseCase(this.repository, this.audioManager);

  Future<void> call(Song song) async {
    // 1. 获取真实的播放地址 (可能是 Presigned URL)
    final streamUrl = await repository.getStreamUrl(song.id);
  
    // 2. 将 URL 和元数据传递给 Audio Service
    // 注意：这里不直接操作 UI，而是操作 Service
    await audioManager.play(MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      artUri: Uri.parse(song.coverUrl),
      extras: {'url': streamUrl},
    ));
  }
}
```

#### BLoC 实现 (player_bloc.dart)

```dart
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioManager _audioManager;

  PlayerBloc(this._audioManager) : super(PlayerInitial()) {
    // 监听底层音频流，转换为 UI 状态
    _audioManager.playerStateStream.listen((state) {
      add(PlayerStateChanged(state));
    });

    on<PlayRequested>((event, emit) async {
       // 调用 UseCase 或直接调用 Manager
       await _audioManager.playFromUrl(event.url);
    });
  
    on<PlayerStateChanged>((event, emit) {
      emit(state.copyWith(
        isPlaying: event.state.playing,
        processingState: event.state.processingState
      ));
    });
  }
}
```

这个架构方案确保了你的前端代码不仅现在能跑通，而且在未来一年内代码量增加十倍时，依然清晰、可维护、性能优异。
