import 'package:injectable/injectable.dart';
import 'package:music_app/features/favorites/data/datasources/favorites_api.dart';
import 'package:music_app/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:music_app/features/home/domain/entities/song.dart';

@LazySingleton(as: FavoritesRepository)
class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesApi _api;

  FavoritesRepositoryImpl(this._api);

  @override
  Future<List<Song>> getMyFavorites() async {
    try {
      final response = await _api.getMyFavorites();
      if (response.isSuccess && response.value != null) {
        // DTO -> Entity 转换
        return response.value!.map((dto) => dto.toEntity()).toList();
      }
      return [];
    } catch (e) {
      // 可以在这里记录日志
      rethrow;
    }
  }

  @override
  Future<Set<String>> getFavoriteIds() async {
    try {
      final response = await _api.getFavoriteIds();
      if (response.isSuccess && response.value != null) {
        // List -> Set (为了 O(1) 的查找性能)
        return response.value!.toSet();
      }
      return {};
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> toggleFavorite(String songId) async {
    try {
      final response = await _api.toggleFavorite(songId);
      if (response.isSuccess && response.value != null) {
        return response.value!;
      }
      throw Exception("Failed to toggle favorite");
    } catch (e) {
      rethrow;
    }
  }
}
