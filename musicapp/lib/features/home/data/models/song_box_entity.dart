import 'package:objectbox/objectbox.dart';
import 'package:music_app/features/home/domain/entities/song.dart';

@Entity()
class SongBoxEntity {
  @Id()
  int id = 0; // ObjectBox 内部自增 ID，初始必须为 0

  @Unique() // 唯一索引，对应后端 GUID
  String serverId;

  String title;
  String artist;
  String album;
  String url;
  String? coverUrl;

  SongBoxEntity({
    this.id = 0,
    required this.serverId,
    required this.title,
    required this.artist,
    required this.album,
    required this.url,
    this.coverUrl,
  });

  // 辅助方法：Domain -> Box
  static SongBoxEntity fromDomain(Song song) {
    return SongBoxEntity(
      serverId: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      url: song.url,
      coverUrl: song.coverUrl,
    );
  }

  // 辅助方法：Box -> Domain
  Song toDomain() {
    return Song(
      id: serverId, // 恢复回 GUID
      title: title,
      artist: artist,
      album: album,
      url: url,
      coverUrl: coverUrl,
    );
  }
}
