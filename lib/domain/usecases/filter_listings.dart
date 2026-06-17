import 'package:gulflands/domain/entities/land_plot.dart';
import 'package:gulflands/domain/repositories/land_repository.dart';
import 'package:gulflands/models/sort_option.dart';

class FilterListings {
  FilterListings(this.repository);
  final LandRepository repository;

  Future<List<LandPlot>> call({
    Country? country,
    SortOption? sortBy,
    String? searchQuery,
  }) async {
    final List<LandPlot> listings = await repository.getLandListings();

    List<LandPlot> filtered = listings;

    if (country != null) {
      filtered = filtered
          .where((LandPlot plot) => plot.country == country)
          .toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final String query = searchQuery.toLowerCase();
      filtered = filtered.where((LandPlot plot) {
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
        return <LandPlot>[...listings]
          ..sort((LandPlot a, LandPlot b) => a.price.compareTo(b.price));
      case SortOption.priceDesc:
        return <LandPlot>[...listings]
          ..sort((LandPlot a, LandPlot b) => b.price.compareTo(a.price));
      case SortOption.areaAsc:
        return <LandPlot>[...listings]
          ..sort((LandPlot a, LandPlot b) => a.area.compareTo(b.area));
      case SortOption.areaDesc:
        return <LandPlot>[...listings]
          ..sort((LandPlot a, LandPlot b) => b.area.compareTo(a.area));
      case SortOption.newest:
        return <LandPlot>[...listings]
          ..sort((LandPlot a, LandPlot b) => b.createdAt.compareTo(a.createdAt));
      case SortOption.oldest:
        return <LandPlot>[...listings]
          ..sort((LandPlot a, LandPlot b) => a.createdAt.compareTo(b.createdAt));
      default:
        return listings;
    }
  }
}
