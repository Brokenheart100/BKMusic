import 'package:objectbox/objectbox.dart';
import 'package:music_app/features/home/domain/entities/song.dart';

@Entity()
class SongBoxEntity {
  @Id()
  int id = 0; // ObjectBox 内部自增 ID (int)

  @Unique()
  @Index()
  String serverId; // 后端业务 ID (String GUID)

  String title;
  String artist;
  String album;
  String url;
  String? coverUrl;

  @Property(type: PropertyType.date)
  DateTime cachedAt;

  SongBoxEntity({
    this.id = 0,
    required this.serverId,
    required this.title,
    required this.artist,
    required this.album,
    required this.url,
    this.coverUrl,
    required this.cachedAt,
  });

  // Domain -> Box
  factory SongBoxEntity.fromDomain(Song song) {
    return SongBoxEntity(
      serverId: song.id, // 将 Domain ID 存入 serverId
      title: song.title,
      artist: song.artist,
      album: song.album,
      url: song.url,
      coverUrl: song.coverUrl,
      cachedAt: DateTime.now(),
    );
  }

  // Box -> Domain
  Song toDomain() {
    return Song(
      id: serverId, // 取出 serverId 作为 Domain ID
      title: title,
      artist: artist,
      album: album,
      url: url,
      coverUrl: coverUrl,
    );
  }
}
