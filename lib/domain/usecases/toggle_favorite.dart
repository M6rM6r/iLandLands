import 'package:gulflands/domain/repositories/land_repository.dart';

class ToggleFavorite {
  ToggleFavorite(this.repository);
  final LandRepository repository;

  Future<void> call(String id) async {
    final List<String> favoriteIds = await repository.getFavoriteIds();
    if (favoriteIds.contains(id)) {
      await repository.removeFromFavorites(id);
    } else {
      await repository.addToFavorites(id);
    }
  }
}
