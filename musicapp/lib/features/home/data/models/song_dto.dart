import 'package:json_annotation/json_annotation.dart';
import 'package:music_app/features/home/domain/entities/song.dart';

part 'song_dto.g.dart';

@JsonSerializable()
class SongDto {
  final String id;
  final String title;

  @JsonKey(name: 'artist')
  final String artist;

  @JsonKey(defaultValue: 'Unknown Album')
  final String? album;

  final String url;
  final String? coverUrl;

  @JsonKey(name: 'duration')
  final double? duration;

  final String? lyricUrl;

  SongDto({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.url,
    this.coverUrl,
    this.duration,
    this.lyricUrl,
  });

  factory SongDto.fromJson(Map<String, dynamic> json) =>
      _$SongDtoFromJson(json);

  // 【核心修复】添加 toJson 方法，消除警告
  Map<String, dynamic> toJson() => _$SongDtoToJson(this);

  // 转换逻辑
  Song toEntity() => Song(
        id: id,
        title: title,
        artist: artist,
        album: album ?? 'Unknown Album',
        url: url,
        coverUrl: coverUrl,
        duration: Duration(seconds: duration?.toInt() ?? 0),
        lyricUrl: lyricUrl,
      );
}
