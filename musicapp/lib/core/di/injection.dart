import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:music_app/core/di/injection.config.dart';
import 'package:music_app/core/network/dio_interceptor.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  await getIt.init();
  final dio = getIt<Dio>();
  dio.interceptors.add(getIt<AuthInterceptor>());
}
