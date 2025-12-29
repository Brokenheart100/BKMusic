import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/features/home/data/datasources/music_api.dart';
import 'package:music_app/features/home/data/datasources/music_local_datasource.dart'; // 引入
import 'package:music_app/features/home/data/models/song_box_entity.dart'; // 引入
import 'package:music_app/features/home/domain/entities/song.dart';
import 'package:music_app/features/home/domain/repositories/music_repository.dart';

@LazySingleton(as: MusicRepository)
class MusicRepositoryImpl implements MusicRepository {
  final MusicApi _api;
  final MusicLocalDataSource _localDataSource; // 注入本地源
  final Logger _logger = getIt<Logger>();

  MusicRepositoryImpl(this._api, this._localDataSource);

  @override
  Future<List<Song>> getSongs() async {
    try {
      // 1. 尝试网络请求
      final response = await _api.getSongs();

      if (response.isSuccess && response.value != null) {
        final domainSongs =
            response.value!.map((dto) => dto.toEntity()).toList();

        // 2. 【异步写入缓存】
        // 我们不等待缓存写入完成直接返回，让 UI 响应更快 (Fire and Forget)
        // 转换 Domain -> Box Entity
        final boxEntities =
            domainSongs.map((s) => SongBoxEntity.fromDomain(s)).toList();

        _localDataSource.cacheSongs(boxEntities).then((_) {
          _logger.d("💾 [Repo] 歌曲已缓存到 ObjectBox (${boxEntities.length} 首)");
        }).catchError((e) {
          _logger.e("❌ [Repo] 缓存写入失败", error: e);
        });

        return domainSongs;
      } else {
        throw Exception("Server Error");
      }
    } catch (e) {
      // 3. 【降级策略】网络失败，读取本地缓存
      _logger.w("⚠️ [Repo] 网络请求失败，尝试读取本地缓存...", error: e);

      final cachedEntities = await _localDataSource.getCachedSongs();

      if (cachedEntities.isNotEmpty) {
        _logger.i("✅ [Repo] 已从 ObjectBox 恢复 ${cachedEntities.length} 首歌曲");
        // 转换 Box Entity -> Domain
        return cachedEntities.map((c) => c.toDomain()).toList();
      } else {
        // 4. 既没网也没缓存，抛出异常给 UI 显示 Error Widget
        _logger.e("❌ [Repo] 本地缓存为空，无法展示数据");
        rethrow;
      }
    }
  }
}
