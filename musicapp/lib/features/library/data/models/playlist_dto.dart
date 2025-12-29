import 'package:json_annotation/json_annotation.dart';
import 'package:music_app/features/home/data/models/song_dto.dart';

part 'playlist_dto.g.dart';

// 1. 歌单列表项
@JsonSerializable()
class PlaylistDto {
  final String id;
  final String name;
  final String? coverUrl;
  final int songCount;

  PlaylistDto({
    required this.id,
    required this.name,
    this.coverUrl,
    required this.songCount,
  });

  factory PlaylistDto.fromJson(Map<String, dynamic> json) =>
      _$PlaylistDtoFromJson(json);

  // 【新增】补全 toJson，消除警告
  Map<String, dynamic> toJson() => _$PlaylistDtoToJson(this);
}

// 2. 歌单详情
@JsonSerializable()
class PlaylistDetailDto {
  final String id;
  final String name;

  // 详情里包含歌曲列表
  final List<SongDto> songs;

  PlaylistDetailDto({
    required this.id,
    required this.name,
    required this.songs,
  });

  factory PlaylistDetailDto.fromJson(Map<String, dynamic> json) =>
      _$PlaylistDetailDtoFromJson(json);

  // 【新增】补全 toJson，消除警告
  Map<String, dynamic> toJson() => _$PlaylistDetailDtoToJson(this);
}
