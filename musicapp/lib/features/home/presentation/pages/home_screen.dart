import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/core/router/app_router.dart';
import 'package:music_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:music_app/features/home/domain/entities/song.dart';
import 'package:music_app/features/home/presentation/providers/home_providers.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(playerControllerProvider);
    final songsAsync = ref.watch(songsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final nickname = currentUser?.nickname ?? "Guest";
    final avatarUrl = currentUser?.avatarUrl;

    return Scaffold(
      extendBodyBehindAppBar: true, // 让 Banner 延伸到顶部
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.menu), // 装饰性图标
        actions: [
          // 原有的搜索按钮 (保留)
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Search",
            onPressed: () => context.push(Routes.search),
          ),

          const SizedBox(width: 8),

          // 【新增】用户头像下拉菜单
          PopupMenuButton<String>(
            // 图标：圆形头像
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.black, size: 20)
                  : null,
            ),
            tooltip: "Account",
            offset: const Offset(0, 45), // 菜单向下偏移一点
            color: const Color(0xFF2C2C2C), // 深色背景
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),

            // 点击菜单项的回调
            onSelected: (value) async {
              if (value == 'logout') {
                // 执行登出逻辑
                await ref.read(authControllerProvider).logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Logged out successfully")),
                  );
                }
              }
            },

            // 菜单内容
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              // 1. 用户信息展示 (不可点)
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nickname,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("user@example.com",
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12)),
                    const Divider(height: 20, thickness: 0.5),
                  ],
                ),
              ),
              // 2. 个人资料
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20, color: Colors.white70),
                    SizedBox(width: 12),
                    Text("Profile", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              // 3. 退出登录 (红色)
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Text("Log Out", style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: songsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (songs) {
          if (songs.isEmpty) return const Center(child: Text("No songs"));

          // 随机取一首做 Banner，剩下的做列表
          final bannerSong = songs.first;
          final recentSongs = songs.take(5).toList(); // 模拟“最近播放”
          final popularSongs = songs.reversed.take(10).toList(); // 模拟“流行”

          return CustomScrollView(
            slivers: [
              // 1. 顶部大 Banner
              SliverToBoxAdapter(
                child: _HeroBanner(
                    song: bannerSong,
                    onPlay: () => _play(controller, bannerSong)),
              ),

              // 2. 标题：New Releases
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Text("New Releases",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),

              // 3. 横向滚动列表
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recentSongs.length,
                    itemBuilder: (context, index) => _HorizontalCard(
                      song: recentSongs[index],
                      onTap: () => _play(controller, recentSongs[index]),
                    ),
                  ),
                ),
              ),

              // 4. 标题：Popular Songs
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Text("Popular Songs",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),

              // 5. 竖向列表 (Responsive Grid)
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400, // 宽屏时显示多列
                    mainAxisExtent: 80, // 固定高度
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _VerticalListTile(
                      song: popularSongs[index],
                      index: index + 1,
                      onTap: () => _play(controller, popularSongs[index]),
                    ),
                    childCount: popularSongs.length,
                  ),
                ),
              ),

              // 底部留白给 MiniPlayer
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  void _play(PlayerController controller, Song song) {
    controller.playMediaItem(MediaItem(
      id: song.url,
      title: song.title,
      artist: song.artist,
      album: song.album,
      artUri: song.coverUrl != null ? Uri.parse(song.coverUrl!) : null,
    ));
  }
}

// --- 组件 1: 顶部大 Banner ---
class _HeroBanner extends StatelessWidget {
  final Song song;
  final VoidCallback onPlay;

  const _HeroBanner({required this.song, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 340,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          image: DecorationImage(
            image: CachedNetworkImageProvider(song.coverUrl ?? ""),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 15))
          ]),
      child: Stack(
        children: [
          // 渐变遮罩
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
              ),
            ),
          ),
          // 文字内容
          Positioned(
            left: 24,
            bottom: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text("Trending Now",
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(height: 12),
                Text(song.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
                Text(song.artist,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Listen Now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- 组件 2: 横向卡片 ---
class _HorizontalCard extends StatefulWidget {
  final Song song;
  final VoidCallback onTap;

  const _HorizontalCard({required this.song, required this.onTap});

  @override
  State<_HorizontalCard> createState() => _HorizontalCardState();
}

class _HorizontalCardState extends State<_HorizontalCard> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 160,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          transform: isHover
              ? Matrix4.translationValues(0, -5, 0)
              : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(
                          widget.song.coverUrl ?? ""),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: isHover
                      ? Center(
                          child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                              color: Colors.white24, shape: BoxShape.circle),
                          child:
                              const Icon(Icons.play_arrow, color: Colors.white),
                        ))
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(widget.song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(widget.song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 组件 3: 竖向列表项 ---
class _VerticalListTile extends StatefulWidget {
  final Song song;
  final int index;
  final VoidCallback onTap;

  const _VerticalListTile(
      {required this.song, required this.index, required this.onTap});

  @override
  State<_VerticalListTile> createState() => _VerticalListTileState();
}

class _VerticalListTileState extends State<_VerticalListTile> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isHover
                ? Colors.white.withOpacity(0.1)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Text("#${widget.index}",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: widget.song.coverUrl ?? "",
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.song.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.song.artist,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5))),
                  ],
                ),
              ),
              Text("3:45",
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.3))), // 临时时长
              const SizedBox(width: 16),
              if (isHover)
                Icon(Icons.play_circle_fill,
                    color: Theme.of(context).primaryColor, size: 32)
              else
                Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
