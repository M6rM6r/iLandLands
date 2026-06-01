import 'package:gulflands/domain/repositories/land_repository.dart';

class GetFavorites {

  GetFavorites(this.repository);
  final LandRepository repository;

  Future<List<String>> call() async {
    return repository.getFavoriteIds();
  }
}