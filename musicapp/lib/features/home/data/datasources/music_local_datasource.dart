import 'package:injectable/injectable.dart';
import 'package:music_app/core/db/objectbox_manager.dart';
import 'package:music_app/features/home/data/models/song_box_entity.dart';
import 'package:music_app/objectbox.g.dart'; // 引入生成的 Box 定义

abstract class MusicLocalDataSource {
  Future<List<SongBoxEntity>> getCachedSongs();
  Future<void> cacheSongs(List<SongBoxEntity> songs);
}

@LazySingleton(as: MusicLocalDataSource)
class MusicLocalDataSourceImpl implements MusicLocalDataSource {
  final ObjectBoxManager _dbManager;
  final Box<SongBoxEntity> _box;

  MusicLocalDataSourceImpl(this._dbManager)
      : _box = _dbManager.store.box<SongBoxEntity>();

  @override
  Future<List<SongBoxEntity>> getCachedSongs() async {
    // getAll() 是同步的，但在 Future 中返回保持接口一致性
    return _box.getAll();
  }

  @override
  Future<void> cacheSongs(List<SongBoxEntity> songs) async {
    // 策略：由于 ID 是自增的，简单的 putMany 可能会导致重复数据
    // 我们采用 "Smart Put"：根据 serverId 查找已存在的记录，复用其 ID

    final List<SongBoxEntity> toSave = [];

    // 这里使用 Query 进行优化，或者简单粗暴一点：先清空再插入（缓存场景常用）
    // 方案 A：清空旧缓存，插入新缓存 (最简单，适合列表刷新)
    /*
    _box.removeAll();
    _box.putMany(songs);
    */

    // 方案 B：智能更新 (推荐，保留旧数据 ID)
    for (var newSong in songs) {
      // 查询是否存在
      final query =
          _box.query(SongBoxEntity_.serverId.equals(newSong.serverId)).build();
      final existing = query.findFirst();
      query.close();

      if (existing != null) {
        newSong.id = existing.id; // 复用 ID，这就变成了 Update 操作
      }
      toSave.add(newSong);
    }

    _box.putMany(toSave);
  }
}
