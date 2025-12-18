import 'package:music_app/features/home/domain/entities/song.dart';

abstract class SearchRepository {
  Future<List<Song>> search(String query);
}
