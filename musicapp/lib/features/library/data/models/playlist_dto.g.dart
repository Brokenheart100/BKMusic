// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistDto _$PlaylistDtoFromJson(Map<String, dynamic> json) => PlaylistDto(
      id: json['id'] as String,
      name: json['name'] as String,
      coverUrl: json['coverUrl'] as String?,
      songCount: (json['songCount'] as num).toInt(),
    );

Map<String, dynamic> _$PlaylistDtoToJson(PlaylistDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'coverUrl': instance.coverUrl,
      'songCount': instance.songCount,
    };

PlaylistDetailDto _$PlaylistDetailDtoFromJson(Map<String, dynamic> json) =>
    PlaylistDetailDto(
      id: json['id'] as String,
      name: json['name'] as String,
      songs: (json['songs'] as List<dynamic>)
          .map((e) => SongDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlaylistDetailDtoToJson(PlaylistDetailDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'songs': instance.songs,
    };
