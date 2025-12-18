// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:logger/logger.dart' as _i974;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../features/auth/data/datasources/auth_api.dart' as _i367;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/home/data/datasources/music_api.dart' as _i91;
import '../../features/home/data/datasources/music_local_datasource.dart'
    as _i227;
import '../../features/home/data/repositories/music_repository_impl.dart'
    as _i371;
import '../../features/home/domain/repositories/music_repository.dart' as _i392;
import '../../features/home/domain/usecases/get_songs_usecase.dart' as _i986;
import '../../features/library/data/datasources/playlist_api.dart' as _i536;
import '../../features/search/data/datasources/search_api.dart' as _i478;
import '../../features/search/data/repositories/search_repository_impl.dart'
    as _i1017;
import '../../features/search/domain/repositories.dart' as _i963;
import '../db/objectbox_manager.dart' as _i891;
import '../network/dio_interceptor.dart' as _i32;
import '../services/audio_handler.dart' as _i827;
import '../services/audio_manager.dart' as _i856;
import '../services/token_storage.dart' as _i2;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    gh.singleton<_i974.Logger>(() => registerModule.logger);
    gh.singleton<_i367.AuthApi>(() => registerModule.authApi);
    gh.singleton<_i361.Dio>(() => registerModule.dio);
    gh.singleton<_i478.SearchApi>(() => registerModule.searchApi);
    gh.singleton<_i536.PlaylistApi>(() => registerModule.playlistApi);
    await gh.singletonAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.singleton<_i91.MusicApi>(() => registerModule.musicApi);
    await gh.singletonAsync<_i827.MusicHandler>(
      () => registerModule.musicHandler,
      preResolve: true,
    );
    await gh.singletonAsync<_i891.ObjectBoxManager>(
      () => registerModule.objectBoxManager,
      preResolve: true,
    );
    gh.lazySingleton<_i963.SearchRepository>(
        () => _i1017.SearchRepositoryImpl(gh<_i478.SearchApi>()));
    gh.lazySingleton<_i227.MusicLocalDataSource>(
        () => _i227.MusicLocalDataSourceImpl(gh<_i891.ObjectBoxManager>()));
    gh.singleton<_i2.TokenStorage>(
        () => _i2.TokenStorage(gh<_i460.SharedPreferences>()));
    gh.factory<_i32.AuthInterceptor>(() => _i32.AuthInterceptor(
          gh<_i974.Logger>(),
          gh<_i2.TokenStorage>(),
        ));
    gh.singleton<_i856.AudioManager>(
        () => _i856.AudioManager(gh<_i827.MusicHandler>()));
    gh.lazySingleton<_i392.MusicRepository>(() => _i371.MusicRepositoryImpl(
          gh<_i91.MusicApi>(),
          gh<_i227.MusicLocalDataSource>(),
        ));
    gh.factory<_i986.GetSongsUseCase>(
        () => _i986.GetSongsUseCase(gh<_i392.MusicRepository>()));
    gh.lazySingleton<_i787.AuthRepository>(() => _i153.AuthRepositoryImpl(
          gh<_i367.AuthApi>(),
          gh<_i2.TokenStorage>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
