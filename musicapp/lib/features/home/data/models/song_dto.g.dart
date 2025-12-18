// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SongDto _$SongDtoFromJson(Map<String, dynamic> json) => SongDto(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String? ?? 'Unknown Album',
      url: json['url'] as String,
      coverUrl: json['coverUrl'] as String?,
    );

Map<String, dynamic> _$SongDtoToJson(SongDto instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artist': instance.artist,
      'album': instance.album,
      'url': instance.url,
      'coverUrl': instance.coverUrl,
    };
