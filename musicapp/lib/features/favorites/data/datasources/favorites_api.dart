import 'package:dio/dio.dart';
import 'package:music_app/core/network/api_response.dart';
import 'package:music_app/features/home/data/models/song_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'favorites_api.g.dart';

@RestApi()
abstract class FavoritesApi {
  factory FavoritesApi(Dio dio) = _FavoritesApi;

  @GET("/favorites")
  Future<ApiResponse<List<SongDto>>> getMyFavorites();

  @GET("/favorites/ids")
  Future<ApiResponse<List<String>>> getFavoriteIds();

  @POST("/favorites/{id}/toggle")
  Future<ApiResponse<bool>> toggleFavorite(@Path() String id);
}
