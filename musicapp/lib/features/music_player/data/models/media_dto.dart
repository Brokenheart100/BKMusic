import 'package:json_annotation/json_annotation.dart';
part 'media_dto.g.dart';

// 【新增】请求 DTO，对应后端的 InitUploadRequest
@JsonSerializable()
class InitUploadRequest {
  final String? songId; // 对应后端 Guid?
  final String fileName;
  final String contentType;
  final String? category; // 对应后端 string? Category

  InitUploadRequest({
    this.songId,
    required this.fileName,
    required this.contentType,
    this.category,
  });

  Map<String, dynamic> toJson() => _$InitUploadRequestToJson(this);
}

@JsonSerializable()
class InitUploadResponse {
  final String uploadId;
  final String uploadUrl;
  final String key;
  InitUploadResponse(
      {required this.uploadId, required this.uploadUrl, required this.key});
  factory InitUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$InitUploadResponseFromJson(json);
}
