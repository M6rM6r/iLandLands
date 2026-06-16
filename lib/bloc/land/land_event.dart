part of 'land_bloc.dart';

abstract class LandEvent extends Equatable {
  const LandEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class LoadLandListings extends LandEvent {
  const LoadLandListings({this.country, this.sortBy, this.searchQuery});

  final Country? country;
  final SortOption? sortBy;
  final String? searchQuery;

  @override
  List<Object?> get props => <Object?>[country, sortBy, searchQuery];
}

class RefreshLandListings extends LandEvent {
  const RefreshLandListings();
}

class SearchLandListings extends LandEvent {
  const SearchLandListings(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

class FilterLandListings extends LandEvent {
  const FilterLandListings(this.country);

  final Country? country;

  @override
  List<Object?> get props => <Object?>[country];
}

class SortLandListings extends LandEvent {
  const SortLandListings(this.sortBy);

  final SortOption? sortBy;

  @override
  List<Object?> get props => <Object?>[sortBy];
}

class ToggleFavorite extends LandEvent {
  const ToggleFavorite(this.plotId);

  final String plotId;

  @override
  List<Object?> get props => <Object?>[plotId];
}

class LoadMoreListings extends LandEvent {
  const LoadMoreListings();
}
