import 'package:gulflands/domain/entities/land_plot.dart';
import 'package:gulflands/domain/repositories/land_repository.dart';

enum SortOption {
  priceAsc,
  priceDesc,
  areaAsc,
  areaDesc,
  newest,
  oldest,
}

class FilterListings {

  FilterListings(this.repository);
  final LandRepository repository;

  Future<List<LandPlot>> call({
    Country? country,
    SortOption? sortBy,
    String? searchQuery,
  }) async {
    final listings = await repository.getLandListings();

    var filtered = listings;

    if (country != null) {
      filtered = filtered.where((plot) => plot.country == country).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((plot) {
        return plot.title.toLowerCase().contains(query) ||
            plot.location.toLowerCase().contains(query) ||
            plot.description.toLowerCase().contains(query);
      }).toList();
    }

    if (sortBy != null) {
      filtered = _sortListings(filtered, sortBy);
    }

    return filtered;
  }

  List<LandPlot> _sortListings(List<LandPlot> listings, SortOption sortBy) {
    switch (sortBy) {
      case SortOption.priceAsc:
        return [...listings]..sort((a, b) => a.price.compareTo(b.price));
      case SortOption.priceDesc:
        return [...listings]..sort((a, b) => b.price.compareTo(a.price));
      case SortOption.areaAsc:
        return [...listings]..sort((a, b) => a.area.compareTo(b.area));
      case SortOption.areaDesc:
        return [...listings]..sort((a, b) => b.area.compareTo(a.area));
      case SortOption.newest:
        return [...listings]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOption.oldest:
        return [...listings]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
  }
}
