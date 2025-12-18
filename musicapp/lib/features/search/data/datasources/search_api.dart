import 'package:dio/dio.dart';
import 'package:music_app/core/network/api_response.dart';
import 'package:music_app/features/home/data/models/song_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'search_api.g.dart';

@RestApi()
abstract class SearchApi {
  factory SearchApi(Dio dio) = _SearchApi;

  // 对应后端 Search Service 的接口
  @GET("/search")
  Future<ApiResponse<List<SongDto>>> search(@Query("q") String query);
}
