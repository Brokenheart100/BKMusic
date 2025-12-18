import 'package:injectable/injectable.dart';
import 'package:music_app/features/home/domain/repositories/music_repository.dart';
import 'package:music_app/features/home/domain/entities/song.dart';

@injectable
class GetSongsUseCase {
  final MusicRepository _repository;

  GetSongsUseCase(this._repository);

  Future<List<Song>> call() async {
    return await _repository.getSongs();
  }
}
