
### 第一优先级：核心播放体验补全 (Core Experience)

目前的播放器能响，但还不够“聪明”。

1. **播放模式 (Loop / Shuffle)**

   * **现状**：UI 上有按钮，但点了没反应。
   * **实现**：
     * **UI**：点击按钮切换状态（单曲循环、列表循环、随机）。
     * **Handler**：调用 `_player.setLoopMode` 和 `_player.setShuffleModeEnabled`。
     * **State**：需要监听 `_player.shuffleModeEnabledStream` 和 `loopModeStream` 并更新到 Riverpod。
2. **歌词同步显示 (Lyrics)**

   * **现状**：全屏页还没有歌词。
   * **后端**：需要在上传时支持 `.lrc` 文件上传，或者由 Worker 自动从 MP3 提取内嵌歌词（TagLib 支持），存入数据库或 MinIO。
   * **前端**：
     * 解析 `.lrc` 文件。
     * 使用 `StreamBuilder` 监听当前播放进度。
     * 实现歌词滚动效果（高亮当前行，自动滚动）。
3. **播放队列管理 (Queue / Next Up)**

   * **现状**：目前点击只能播单曲，没有“下一首播放”或“播放列表”的概念。
   * **实现**：
     * 需要一个“当前播放列表”的抽屉（Drawer）或弹窗。
     * 支持拖拽排序（`ReorderableListView`）。
     * 支持滑动删除待播歌曲。

---

### 第二优先级：内容发现与管理 (Discovery & Library)

这是 `features/library` 和 `features/search` 目录目前缺失的内容。

4. **全局搜索 (Search)**

   * **现状**：目录里有 `search/` 但没实现。
   * **后端**：Postgres 的 `LIKE` 查询在数据量大时太慢。企业级通常引入 **Meilisearch** 或 **Elasticsearch** 容器（Aspire 支持）。
   * **前端**：搜索建议、搜索历史、结果分类展示（单曲、歌手、专辑）。
5. **歌单系统 (Playlists)**

   * **现状**：只有“所有歌曲”，没有“我的歌单”。
   * **实现**：
     * **CRUD**：创建歌单、修改封面、添加歌曲到歌单。
     * **收藏**：喜欢歌曲（红心），实际上是添加到了一个特殊的“我喜欢的音乐”歌单中。
6. **离线下载 (Offline Mode)**

   * **现状**：只能在线流媒体播放。
   * **实现**：
     * 利用 `dio.download` 下载原始文件或 HLS 切片（HLS 下载较复杂）。
     * 使用 **ObjectBox/Isar** 记录已下载的文件路径。
     * `AudioHandler` 播放时判断：如果本地有，播本地；没有，播网络。

---

### 第三优先级：用户系统与社交 (User & Social)

7. **用户个人中心 (Profile)**

   * **功能**：修改昵称、上传头像（复用 Media Service）、修改密码。
   * **UI**：设置页面。
8. **多端同步 (Sync)**

   * **功能**：我在电脑端听到了第 30 秒暂停，打开手机端应该能同步进度继续播。
   * **实现**：需要后端记录 `UserPlayHistory`，包含 `SongId` 和 `Position`。

---

### 第四优先级：UI/UX 细节打磨 (Polish)

9. **桌面端原生集成**

   * **系统托盘 (System Tray)**：最小化到右下角托盘，右键菜单控制播放。
   * **系统媒体控制 (SMTC)**：Windows 任务栏预览图上的 上一首/暂停/下一首 按钮（`audio_service` 已经帮我们做了一部分，需要验证）。
   * **快捷键**：除了空格，还需要支持键盘上的媒体键（Play/Pause 键）。
10. **主题切换**

    * 支持亮色/暗色模式切换，并持久化存储到 `SharedPreferences`。

---

### 推荐的下一步开发路线

建议按照以下顺序攻克：

1. **完善播放控制**：先把循环、随机、播放列表抽屉做出来。（这是播放器的基本尊严）。
2. **歌词系统**：这是最能提升视觉效果的功能。
3. **搜索功能**：对接后端简单的 SQL 搜索即可，暂不需要 ES。
4. **歌单 CRUD**：让用户能组织自己的音乐。

您的架构非常稳固，在此基础上添加这些功能就像搭积木一样，只需要在对应的 Feature 目录下填充 `Data -> Domain -> Presentation` 即可。加油！
