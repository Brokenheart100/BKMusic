import 'package:injectable/injectable.dart';
import 'package:music_app/features/home/data/datasources/music_api.dart';
import 'package:music_app/features/home/data/datasources/music_local_datasource.dart';
import 'package:music_app/features/home/domain/entities/song.dart';
import 'package:music_app/features/home/domain/repositories/music_repository.dart';
import 'package:music_app/features/home/data/models/song_box_entity.dart'; // 换成 ObjectBox 实体

@LazySingleton(as: MusicRepository)
class MusicRepositoryImpl implements MusicRepository {
  final MusicApi _api;
  final MusicLocalDataSource _localDataSource;

  MusicRepositoryImpl(this._api, this._localDataSource);

  @override
  Future<List<Song>> getSongs() async {
    try {
      // 1. 网络请求
      final response = await _api.getSongs();
      if (response.isSuccess && response.value != null) {
        final domainSongs =
            response.value!.map((dto) => dto.toEntity()).toList();

        // 2. 转换并缓存
        final boxEntities =
            domainSongs.map((s) => SongBoxEntity.fromDomain(s)).toList();
        // 不 await，让它异步去写，不阻塞 UI
        _localDataSource.cacheSongs(boxEntities);

        return domainSongs;
      } else {
        throw Exception("Server Error");
      }
    } catch (e) {
      // 3. 降级：读缓存
      final cached = await _localDataSource.getCachedSongs();
      if (cached.isNotEmpty) {
        return cached.map((e) => e.toDomain()).toList();
      }
      rethrow;
    }
  }
}
