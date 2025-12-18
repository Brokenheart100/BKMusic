import 'package:json_annotation/json_annotation.dart';
import 'package:music_app/features/home/data/models/song_dto.dart'; // 引用已有的 SongDto

part 'playlist_dto.g.dart';

// 1. 歌单列表项 (对应后端 PlaylistDto)
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
}

// 2. 歌单详情 (对应后端 PlaylistDetailDto)
@JsonSerializable()
class PlaylistDetailDto {
  final String id;
  final String name;

  // 详情里包含歌曲列表，复用之前的 SongDto
  final List<SongDto> songs;

  PlaylistDetailDto({
    required this.id,
    required this.name,
    required this.songs,
  });

  factory PlaylistDetailDto.fromJson(Map<String, dynamic> json) =>
      _$PlaylistDetailDtoFromJson(json);
}
