import 'package:injectable/injectable.dart';
import 'package:music_app/features/home/domain/entities/song.dart';
import 'package:music_app/features/search/data/datasources/search_api.dart';
import 'package:music_app/features/search/domain/repositories.dart';

@LazySingleton(as: SearchRepository)
class SearchRepositoryImpl implements SearchRepository {
  final SearchApi _api;

  SearchRepositoryImpl(this._api);

  @override
  Future<List<Song>> search(String query) async {
    try {
      final response = await _api.search(query);
      if (response.isSuccess && response.value != null) {
        return response.value!.map((dto) => dto.toEntity()).toList();
      }
      return [];
    } catch (e) {
      // 实际开发中建议记录日志
      return [];
    }
  }
}
