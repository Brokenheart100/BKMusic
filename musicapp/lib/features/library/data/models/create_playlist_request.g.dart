// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_playlist_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePlaylistRequest _$CreatePlaylistRequestFromJson(
        Map<String, dynamic> json) =>
    CreatePlaylistRequest(
      name: json['name'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$CreatePlaylistRequestToJson(
        CreatePlaylistRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
    };
