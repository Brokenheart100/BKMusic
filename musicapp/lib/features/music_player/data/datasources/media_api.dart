import 'package:dio/dio.dart';
import 'package:music_app/core/network/api_response.dart';
import 'package:music_app/features/music_player/data/models/media_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'media_api.g.dart';

@RestApi()
abstract class MediaApi {
  factory MediaApi(Dio dio) = _MediaApi;

  @POST("/media/upload/init")
  // 【核心修改】参数改为 InitUploadRequest
  Future<ApiResponse<InitUploadResponse>> initUpload(
      @Body() InitUploadRequest body);

  @POST("/media/upload/confirm")
  Future<ApiResponse<void>> confirmUpload(@Body() Map<String, dynamic> body);
}
