import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/features/home/domain/entities/song.dart';
import 'package:music_app/features/home/domain/usecases/get_songs_usecase.dart';

// 注入 UseCase
final getSongsUseCaseProvider = Provider<GetSongsUseCase>((ref) {
  return getIt<GetSongsUseCase>();
});

// 数据源 Provider (自动管理 Loading/Error/Data 状态)
final songsProvider = FutureProvider.autoDispose<List<Song>>((ref) async {
  final useCase = ref.watch(getSongsUseCaseProvider);
  return await useCase();
});
