// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InitUploadRequest _$InitUploadRequestFromJson(Map<String, dynamic> json) =>
    InitUploadRequest(
      songId: json['songId'] as String?,
      fileName: json['fileName'] as String,
      contentType: json['contentType'] as String,
      category: json['category'] as String?,
    );

Map<String, dynamic> _$InitUploadRequestToJson(InitUploadRequest instance) =>
    <String, dynamic>{
      'songId': instance.songId,
      'fileName': instance.fileName,
      'contentType': instance.contentType,
      'category': instance.category,
    };

InitUploadResponse _$InitUploadResponseFromJson(Map<String, dynamic> json) =>
    InitUploadResponse(
      uploadId: json['uploadId'] as String,
      uploadUrl: json['uploadUrl'] as String,
      key: json['key'] as String,
    );

Map<String, dynamic> _$InitUploadResponseToJson(InitUploadResponse instance) =>
    <String, dynamic>{
      'uploadId': instance.uploadId,
      'uploadUrl': instance.uploadUrl,
      'key': instance.key,
    };
