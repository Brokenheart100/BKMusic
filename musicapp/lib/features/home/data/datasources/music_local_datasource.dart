import 'package:injectable/injectable.dart' hide Order; // 隐藏冲突的 Order
import 'package:music_app/core/db/objectbox_manager.dart';
import 'package:music_app/features/home/data/models/song_box_entity.dart';
import 'package:music_app/objectbox.g.dart';
import 'package:objectbox/objectbox.dart' as obx; // 使用前缀

abstract class MusicLocalDataSource {
  Future<List<SongBoxEntity>> getCachedSongs();
  Future<void> cacheSongs(List<SongBoxEntity> songs);
  Future<void> clearCache();
}

@LazySingleton(as: MusicLocalDataSource)
class MusicLocalDataSourceImpl implements MusicLocalDataSource {
  final ObjectBoxManager _dbManager;
  final Box<SongBoxEntity> _box;

  MusicLocalDataSourceImpl(this._dbManager)
      : _box = _dbManager.store.box<SongBoxEntity>();

  @override
  Future<List<SongBoxEntity>> getCachedSongs() async {
    // 简单查询所有，按缓存时间倒序
    final query = _box
        .query()
        .order(SongBoxEntity_.cachedAt, flags: obx.Order.descending)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  @override
  Future<void> cacheSongs(List<SongBoxEntity> newSongs) async {
    // 【核心逻辑：Upsert (插入或更新)】
    // 1. 开启事务以提高性能
    _dbManager.store.runInTransaction(TxMode.write, () {
      for (var newSong in newSongs) {
        // 【核心修复】
        // 使用 serverId (GUID字符串) 来查找，而不是 id (int)
        // SongBoxEntity_.serverId 是生成的查询属性
        final query = _box
            .query(SongBoxEntity_.serverId.equals(newSong.serverId))
            .build();

        final existing = query.findFirst();
        query.close();

        if (existing != null) {
          // 复用旧数据的 internal ID (int)，这样 ObjectBox 就知道是 Update
          newSong.id = existing.id;
        }
        // 如果 existing 为空，newSong.id 保持为 0，ObjectBox 执行 Insert
      }

      // 2. 批量写入
      _box.putMany(newSongs);
    });
  }

  @override
  Future<void> clearCache() async {
    _box.removeAll();
  }
}
