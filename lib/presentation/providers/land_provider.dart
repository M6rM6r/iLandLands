import 'package:flutter/foundation.dart';
import 'package:gulflands/domain/entities/land_plot.dart';
import 'package:gulflands/domain/usecases/filter_listings.dart';
import 'package:gulflands/domain/usecases/get_favorites.dart';
import 'package:gulflands/domain/usecases/get_land_listings.dart';
import 'package:gulflands/domain/usecases/toggle_favorite.dart';

class LandProvider with ChangeNotifier {
  LandProvider({
    required this.getLandListings,
    required this.toggleFavorite,
    required this.getFavorites,
    required this.filterListings,
  });
  final GetLandListings getLandListings;
  final ToggleFavorite toggleFavorite;
  final GetFavorites getFavorites;
  final FilterListings filterListings;

  // ignore: unused_field
  List<LandPlot> _allPlots = <LandPlot>[];
  List<LandPlot> _filteredPlots = <LandPlot>[];
  List<String> _favoriteIds = <String>[];
  Country? _selectedCountry;
  SortOption? _selectedSortOption;
  bool _isLoading = false;
  String? _error;

  List<LandPlot> get filteredPlots => _filteredPlots;
  List<String> get favoriteIds => _favoriteIds;
  Country? get selectedCountry => _selectedCountry;
  SortOption? get selectedSortOption => _selectedSortOption;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadListings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allPlots = await getLandListings();
      _favoriteIds = await getFavorites();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter({Country? country, SortOption? sortOption}) {
    if (country != null) _selectedCountry = country;
    if (sortOption != null) _selectedSortOption = sortOption;
    _applyFilters();
    notifyListeners();
  }

  Future<void> _applyFilters() async {
    _filteredPlots = await filterListings(
      country: _selectedCountry,
      sortBy: _selectedSortOption,
    );
    notifyListeners();
  }

  Future<void> toggleFavoriteForPlot(String id) async {
    await toggleFavorite(id);
    _favoriteIds = await getFavorites();
    notifyListeners();
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);
}
