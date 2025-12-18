import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/features/home/presentation/widgets/song_list_tile.dart'; // 【核心修复】引入组件
import 'package:music_app/features/search/presentation/providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 自动聚焦
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // 透明背景
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. 全局毛玻璃背景
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
              ),
            ),
          ),

          // 2. 内容区域
          SafeArea(
            child: Column(
              children: [
                // --- 顶部搜索栏 ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // 返回按钮
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white70),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      // 搜索框
                      Expanded(
                        child: Hero(
                          tag: 'search_bar', // Hero 动画标签
                          child: Material(
                            color: Colors.transparent,
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              // 更新搜索关键词
                              onChanged: (val) => ref
                                  .read(searchQueryProvider.notifier)
                                  .state = val,
                              style: const TextStyle(
                                  fontSize: 20, color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Search songs, artists...",
                                hintStyle: TextStyle(
                                    // 【修复】使用 withValues
                                    color: Colors.white.withValues(alpha: 0.3)),
                                border: InputBorder.none,
                                suffixIcon: _controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear,
                                            color: Colors.white54),
                                        onPressed: () {
                                          _controller.clear();
                                          ref
                                              .read(
                                                  searchQueryProvider.notifier)
                                              .state = '';
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Colors.white10),

                // --- 结果列表 ---
                Expanded(
                  child: searchResults.when(
                    data: (songs) {
                      if (songs.isEmpty && _controller.text.isNotEmpty) {
                        return _buildEmptyState();
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          // 【核心修复】现在 SongListTile 已经定义并引入了
                          return SongListTile(song: song);
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text("Error: $err")),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 64,
              // 【修复】使用 withValues
              color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text("No results found",
              style: TextStyle(
                  // 【修复】使用 withValues
                  color: Colors.white.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}
