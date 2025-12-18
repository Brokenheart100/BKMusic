import 'package:music_app/features/home/domain/entities/song.dart';

abstract class MusicRepository {
  /// 获取推荐/所有歌曲
  Future<List<Song>> getSongs();
}
