import 'package:json_annotation/json_annotation.dart';

part 'media_dto.g.dart';

// 1. 初始化上传请求
@JsonSerializable()
class InitUploadRequest {
  final String? songId;
  final String fileName;
  final String contentType;
  final String? category;

  InitUploadRequest({
    this.songId,
    required this.fileName,
    required this.contentType,
    this.category,
  });

  // 【新增】补全反序列化，消除 _$InitUploadRequestFromJson 警告
  factory InitUploadRequest.fromJson(Map<String, dynamic> json) =>
      _$InitUploadRequestFromJson(json);

  Map<String, dynamic> toJson() => _$InitUploadRequestToJson(this);
}

// 2. 初始化上传响应
@JsonSerializable()
class InitUploadResponse {
  final String uploadId;
  final String uploadUrl;
  final String key;

  InitUploadResponse(
      {required this.uploadId, required this.uploadUrl, required this.key});

  factory InitUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$InitUploadResponseFromJson(json);

  // 【新增】补全序列化，消除 _$InitUploadResponseToJson 警告
  Map<String, dynamic> toJson() => _$InitUploadResponseToJson(this);
}
