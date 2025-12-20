import 'package:music_app/features/home/domain/entities/song.dart';

class PlaylistDetail {
  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final List<Song> songs;

  const PlaylistDetail({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    required this.songs,
  });

  // 辅助属性：计算总时长（模拟）或歌曲数
  String get stats => "${songs.length} songs • ${songs.length * 3} mins+";
}
