import 'package:json_annotation/json_annotation.dart';
import 'package:music_app/features/home/domain/entities/song.dart';

part 'song_dto.g.dart';

@JsonSerializable()
class SongDto {
  final String id;
  final String title;
  @JsonKey(name: 'artist') // 如果后端字段名不同，这里映射
  final String artist;
  @JsonKey(defaultValue: 'Unknown Album')
  final String? album; // 后端 DTO 暂时没返回 Album，给个默认值
  final String url;
  final String? coverUrl;

  SongDto({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.url,
    this.coverUrl,
  });

  factory SongDto.fromJson(Map<String, dynamic> json) =>
      _$SongDtoFromJson(json);

  // DTO -> Domain Entity 转换方法
  Song toEntity() => Song(
        id: id,
        title: title,
        artist: artist,
        album: album ?? 'Unknown',
        url: url,
        coverUrl: coverUrl,
      );
}
