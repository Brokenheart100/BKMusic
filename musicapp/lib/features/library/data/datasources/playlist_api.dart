import 'package:dio/dio.dart';
import 'package:music_app/core/network/api_response.dart';
import 'package:music_app/features/library/data/models/playlist_dto.dart'; // 【新增】引入 DTO
import 'package:retrofit/retrofit.dart';

part 'playlist_api.g.dart';

@RestApi()
abstract class PlaylistApi {
  factory PlaylistApi(Dio dio) = _PlaylistApi;

  @GET("/playlists")
  Future<ApiResponse<List<PlaylistDto>>> getMyPlaylists();

  @POST("/playlists")
  Future<ApiResponse<String>> createPlaylist(@Body() Map<String, dynamic> body);

  @POST("/playlists/{id}/songs")
  Future<ApiResponse<void>> addSongToPlaylist(
      @Path() String id, @Body() Map<String, dynamic> body);

  @GET("/playlists/{id}")
  Future<ApiResponse<PlaylistDetailDto>> getPlaylistDetail(@Path() String id);
}
