import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/core/router/app_router.dart';
import 'package:music_app/core/ui/skeleton_list.dart';
import 'package:music_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:music_app/features/home/domain/entities/song.dart';
import 'package:music_app/features/home/presentation/enums/user_menu_action.dart';
import 'package:music_app/features/home/presentation/providers/home_providers.dart';
import 'package:music_app/features/music_player/presentation/providers/player_providers.dart';
import 'package:music_app/features/home/presentation/widgets/hero_banner.dart';
import 'package:music_app/features/home/presentation/widgets/horizontal_song_card.dart';
import 'package:music_app/features/home/presentation/widgets/song_list_tile.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.menu),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open_rounded),
            tooltip: "Open Local File",
            onPressed: () {
              ref.read(playerControllerProvider).pickAndPlayLocal();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Search",
            onPressed: () => context.push(Routes.search),
          ),
          const SizedBox(width: 8),

          // 用户菜单
          PopupMenuButton<UserMenuAction>(
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
            offset: const Offset(0, 45),
            color: const Color(0xFF2C2C2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            onSelected: (UserMenuAction action) {
              _handleMenuSelection(context, ref, action);
            },
            itemBuilder: (BuildContext context) =>
                _buildMenuItems(nickname, currentUser?.email),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: songsAsync.when(
        loading: () => const SkeletonList(),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (songs) {
          if (songs.isEmpty) return const Center(child: Text("No songs"));

          final bannerSong = songs.first;
          final recentSongs = songs.take(5).toList();
          final popularSongs = songs.reversed.take(10).toList();

          return CustomScrollView(
            slivers: [
              // 1. Banner
              SliverToBoxAdapter(
                child: HeroBanner(
                  song: bannerSong,
                  onPlay: () => _play(controller, bannerSong),
                ),
              ),

              // 2. New Releases 标题
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Text(
                    "New Releases",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // 3. 横向列表
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recentSongs.length,
                    itemBuilder: (context, index) => HorizontalSongCard(
                      song: recentSongs[index],
                      onTap: () => _play(controller, recentSongs[index]),
                    ),
                  ),
                ),
              ),

              // 4. Popular Songs 标题
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Text(
                    "Popular Songs",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // 5. 竖向列表 (使用拆分后的组件)
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: 80,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => SongListTile(
                      song: popularSongs[index],
                      index: index + 1,
                      onTap: () => _play(controller, popularSongs[index]),
                    ),
                    childCount: popularSongs.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  // --- 辅助逻辑 ---

  void _play(PlayerController controller, Song song) {
    controller.playMediaItem(MediaItem(
      id: song.url,
      title: song.title,
      artist: song.artist,
      album: song.album,
      artUri: song.coverUrl != null ? Uri.parse(song.coverUrl!) : null,
      extras: {'songId': song.id, 'lyricUrl': song.lyricUrl},
    ));
  }

  void _handleMenuSelection(
      BuildContext context, WidgetRef ref, UserMenuAction action) async {
    switch (action) {
      case UserMenuAction.logout:
        await ref.read(authControllerProvider).logout();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Logged out successfully")),
          );
        }
        break;
      case UserMenuAction.profile:
      case UserMenuAction.settings:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Coming soon!")),
        );
        break;
    }
  }

  List<PopupMenuEntry<UserMenuAction>> _buildMenuItems(
      String nickname, String? email) {
    return [
      PopupMenuItem<UserMenuAction>(
        enabled: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nickname,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            Text(email ?? "No email",
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            const Divider(height: 20, thickness: 0.5),
          ],
        ),
      ),
      _buildPopupItem(UserMenuAction.profile),
      const PopupMenuDivider(),
      _buildPopupItem(UserMenuAction.logout),
    ];
  }

  PopupMenuItem<UserMenuAction> _buildPopupItem(UserMenuAction action) {
    return PopupMenuItem<UserMenuAction>(
      value: action,
      child: Row(
        children: [
          Icon(action.icon, size: 20, color: action.iconColor),
          const SizedBox(width: 12),
          Text(action.label, style: TextStyle(color: action.color)),
        ],
      ),
    );
  }
}
