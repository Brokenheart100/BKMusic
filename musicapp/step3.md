
### 第一阶段：离线优先架构 (Offline-First Architecture) —— **最核心升级**

真正的音乐 App 必须支持断网播放（已下载的歌曲）和弱网体验。这需要对现有的 **Data Layer** 进行重大升级。

#### 1. 引入本地数据库 (Local Cache)

* **工具**：**Isar** (性能最强，适合存储成千上万首歌的元数据) 或 **ObjectBox**。
* **架构变更**：
  * 在 `data/datasources` 下新建 `music_local_datasource.dart`。
  * 定义 `SongEntity` (Isar Collection)。
* **逻辑**：
  * `Repository` 不再只调 API。
  * **读取策略**：优先读本地 Isar -> 显示数据 -> 后台静默调 API -> 更新 Isar -> UI 自动刷新 (Stream)。

#### 2. 下载管理器 (Download Manager)

* **工具**：**`background_downloader`** (推荐，支持后台下载、断点续传) 或 **`dio`** (简单下载)。
* **实现**：
  * 点击“下载” -> 将任务加入队列。
  * 下载完成 -> 将文件路径 (`/data/user/0/.../song.mp3`) 存入 Isar 数据库的 `localPath` 字段。
* **播放逻辑升级**：
  * `AudioManager` 在播放前检查：`if (song.localPath != null && File(song.localPath).exists())` -> **播本地文件**。
  * 否则 -> **播网络 URL**。

---

### 第二阶段：极致性能与交互 (Performance & UX)

企业级应用不能有卡顿，加载不能转圈圈。

#### 1. 分页加载 (Infinite Scrolling)

目前我们是一次性拉取所有歌单，数据量大了会卡死。

* **工具**：**`infinite_scroll_pagination`**。
* **实现**：
  * 后端 API 需要支持 `?page=1&pageSize=20`。
  * 前端 UI 使用 `PagedListView` 替换 `ListView`。
  * Repository 层处理分页数据的拼接。

#### 2. 骨架屏 (Shimmer Loading)

告别丑陋的转圈圈 `CircularProgressIndicator`。

* **工具**：**`shimmer`**。
* **实现**：
  * 封装一个 `SongListTileShimmer` 组件（灰色色块闪烁）。
  * 在 `AsyncValue.loading` 状态时显示这个组件。

#### 3. 图片性能优化

* **工具**：`cached_network_image` (已用)。
* **进阶配置**：
  * **`memCacheWidth` / `memCacheHeight`**：列表里的图片很小，不要把 4K 原图解码到内存里！设置 `memCacheHeight: 100` 可以节省 90% 内存，防止列表滑动卡顿。
  * **自定义 Cache Key**：防止 URL 带签名参数变化导致重复下载。

---

### 第三阶段：工程化与国际化 (Engineering & i18n)

#### 1. 国际化 (i18n & l10n)

代码里不能出现 `"Library"`, `"Unknown Artist"` 这种硬编码字符串。

* **工具**：**`flutter_localizations`** + **`intl`** (官方推荐) 或 **`easy_localization`**。
* **实现**：
  * 创建 `l10n/app_en.arb` 和 `l10n/app_zh.arb`。
  * UI 中使用 `S.of(context).library`。

#### 2. 严格的 Lint 规则

* **工具**：**`flutter_lints`** (默认) 或 **`very_good_analysis`** (更严格)。
* **配置**：在 `analysis_options.yaml` 中开启更多规则，强制代码风格统一（如 `const` 构造函数、不使用 `print` 等）。

---

### 第四阶段：自动化测试 (Testing)

这是“能跑”和“敢上线”的区别。

#### 1. 单元测试 (Unit Test)

* **目标**：测试 `Repository`, `UseCase`, `Controller`。
* **工具**：**`mockito`** 或 **`mocktail`**。
* **场景**：
  * Mock API 返回 401，测试 Repository 是否抛出正确的 Failure。
  * 测试 Controller 在 `createPlaylist` 成功后是否刷新了列表。

#### 2. 组件测试 (Widget Test)

* **目标**：测试 UI 组件的渲染。
* **场景**：
  * `SongRowCard` 在 `isPlaying=true` 时是否显示了高亮颜色。
  * 点击红心按钮是否触发了回调。

---

### 第五阶段：桌面端原生深度集成 (Desktop Native)

既然你主打 Windows，这些功能是加分项。

#### 1. 系统托盘 (System Tray)

* **工具**：**`system_tray`** 或 **`tray_manager`**。
* **功能**：关闭窗口时最小化到托盘，右键托盘图标可以切歌、退出。

#### 2. 任务栏进度条与控制 (SMTC)

* **工具**：`audio_service` (已用) + Windows 配置。
* **功能**：在 Windows 任务栏预览窗口中显示 播放/暂停 按钮和 进度条。

#### 3. 键盘快捷键 (Global Shortcuts)

* **工具**：**`hotkey_manager`** (支持全局热键，即使 App 没焦点也能切歌)。
* **功能**：`Ctrl + Alt + Right` 下一首。

---

### 总结：推荐实施顺序

1. **Skeleton (骨架屏)**：最简单，视觉提升最明显。
2. **i18n (国际化)**：尽早做，代码写多了再改很痛苦。
3. **Offline (离线模式)**：技术含量最高，最实用的功能。
4. **Testing (测试)**：为长期维护做准备。

你现在的项目底子非常好，按照这个路线走下去，这就是一个可以写进简历并在面试中大谈特谈的**高级项目**。
