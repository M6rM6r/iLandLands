import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../repositories/land_repository_impl.dart';
import '../models/land_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Network Layer
  sl.registerLazySingleton<Dio>(
    () => Dio(
      BaseOptions(
        baseUrl: 'https://api.gulflands.com/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    )..interceptors.add(LogInterceptor(requestBody: true, responseBody: true)),
  );

  // Repositories
  sl.registerLazySingleton<LandRepository>(() => LandRepositoryImpl(sl<Dio>()));
}
