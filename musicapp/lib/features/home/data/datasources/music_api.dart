import 'package:dio/dio.dart';
import 'package:music_app/core/network/api_response.dart';
import 'package:music_app/features/home/data/models/song_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'music_api.g.dart';

@RestApi()
abstract class MusicApi {
  factory MusicApi(Dio dio) = _MusicApi;

  @GET("/songs")
  Future<ApiResponse<List<SongDto>>> getSongs();
}
