import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/features/home/domain/entities/song.dart';
import 'package:music_app/features/search/domain/repositories.dart';

// 1. 搜索关键词状态
final searchQueryProvider = StateProvider<String>((ref) => '');

// 2. 搜索结果 Provider (带防抖)
final searchResultsProvider =
    FutureProvider.autoDispose<List<Song>>((ref) async {
  final query = ref.watch(searchQueryProvider);

  // 如果关键词为空，直接返回空列表
  if (query.isEmpty) return [];

  // 【核心修复：防抖逻辑】
  // 1. 定义一个标记，记录当前 Provider 是否被销毁（即用户是否输入了新字符导致重刷）
  bool didDispose = false;
  ref.onDispose(() => didDispose = true);

  // 2. 延迟 500ms
  await Future.delayed(const Duration(milliseconds: 500));

  // 3. 如果在等待期间 Provider 被销毁了，说明这是个“旧请求”，直接退出，不发网络请求
  if (didDispose) {
    throw Exception('Cancelled');
  }

  // 4. 发起真正的网络请求
  final repository = getIt<SearchRepository>();
  return await repository.search(query);
});
